#include "ms_store.h"

// Classic COM support for C++/WinRT (IInitializeWithWindow) needs these
// before the WinRT headers.
#include <unknwn.h>
#include <shobjidl_core.h>

#include <winrt/Windows.Foundation.Collections.h>
#include <winrt/Windows.Foundation.h>
#include <winrt/Windows.Services.Store.h>

#include <flutter/standard_method_codec.h>

#include <optional>
#include <string>
#include <variant>

namespace {

using flutter::EncodableValue;
using flutter::MethodResult;
using winrt::Windows::Foundation::IAsyncOperation;
using winrt::Windows::Services::Store::StoreContext;
using winrt::Windows::Services::Store::StoreProduct;
using winrt::Windows::Services::Store::StorePurchaseStatus;

using Result = std::shared_ptr<MethodResult<EncodableValue>>;

// A desktop app must tell the Store which window owns its dialogs.
StoreContext ContextFor(HWND window) {
  StoreContext context = StoreContext::GetDefault();
  context.as<::IInitializeWithWindow>()->Initialize(window);
  return context;
}

// This app's durable add-on whose Product ID is |token|, or null.
IAsyncOperation<StoreProduct> FindAddOn(StoreContext context,
                                        winrt::hstring token) {
  auto kinds = winrt::single_threaded_vector<winrt::hstring>({L"Durable"});
  auto query = co_await context.GetAssociatedStoreProductsAsync(kinds);
  winrt::check_hresult(query.ExtendedError());
  for (auto const& entry : query.Products()) {
    if (entry.Value().InAppOfferToken() == token) co_return entry.Value();
  }
  co_return nullptr;
}

// Each answer goes back on the window's thread, where the channel lives.
winrt::fire_and_forget Price(HWND window, winrt::hstring token,
                             Result result) {
  winrt::apartment_context ui;
  std::optional<std::string> price;
  std::optional<std::string> error;
  try {
    StoreProduct product = co_await FindAddOn(ContextFor(window), token);
    if (product) price = winrt::to_string(product.Price().FormattedPrice());
  } catch (winrt::hresult_error const& e) {
    error = winrt::to_string(e.message());
  }
  co_await ui;
  if (error) {
    result->Error("store", *error);
  } else if (price) {
    result->Success(EncodableValue(*price));
  } else {
    result->Success();
  }
}

winrt::fire_and_forget Owned(HWND window, winrt::hstring token,
                             Result result) {
  winrt::apartment_context ui;
  std::optional<bool> owned;
  std::optional<std::string> error;
  try {
    auto license = co_await ContextFor(window).GetAppLicenseAsync();
    // Without a license for the app itself (a build not installed from the
    // Store) there is no answer about its add-ons either: say nothing
    // rather than "not owned", which would take Pro away.
    if (license.IsActive()) {
      bool found = false;
      for (auto const& entry : license.AddOnLicenses()) {
        auto addOn = entry.Value();
        if (addOn.InAppOfferToken() == token && addOn.IsActive()) found = true;
      }
      owned = found;
    }
  } catch (winrt::hresult_error const& e) {
    error = winrt::to_string(e.message());
  }
  co_await ui;
  if (error) {
    result->Error("store", *error);
  } else if (owned) {
    result->Success(EncodableValue(*owned));
  } else {
    result->Success();
  }
}

winrt::fire_and_forget Buy(HWND window, winrt::hstring token, Result result) {
  winrt::apartment_context ui;
  std::string outcome = "error";
  std::optional<std::string> error;
  try {
    StoreProduct product = co_await FindAddOn(ContextFor(window), token);
    if (product) {
      // The purchase dialog opens from the window's own thread.
      co_await ui;
      auto purchase = co_await product.RequestPurchaseAsync();
      switch (purchase.Status()) {
        case StorePurchaseStatus::Succeeded:
          outcome = "purchased";
          break;
        case StorePurchaseStatus::AlreadyPurchased:
          outcome = "alreadyPurchased";
          break;
        case StorePurchaseStatus::NotPurchased:
          outcome = "notPurchased";
          break;
        default:
          outcome = "error";
          break;
      }
    }
  } catch (winrt::hresult_error const& e) {
    error = winrt::to_string(e.message());
  }
  co_await ui;
  if (error) {
    result->Error("store", *error);
  } else {
    result->Success(EncodableValue(outcome));
  }
}

}  // namespace

MsStoreChannel::MsStoreChannel(flutter::BinaryMessenger* messenger,
                               HWND window)
    : window_(window) {
  channel_ = std::make_unique<flutter::MethodChannel<EncodableValue>>(
      messenger, "sticky_wall/ms_store",
      &flutter::StandardMethodCodec::GetInstance());
  channel_->SetMethodCallHandler(
      [this](const flutter::MethodCall<EncodableValue>& call,
             std::unique_ptr<MethodResult<EncodableValue>> pending) {
        const auto* token = std::get_if<std::string>(call.arguments());
        if (token == nullptr) {
          pending->Error("arguments", "The add-on's Product ID is missing.");
          return;
        }
        Result result(std::move(pending));
        const winrt::hstring id = winrt::to_hstring(*token);
        const std::string& method = call.method_name();
        if (method == "price") {
          Price(window_, id, result);
        } else if (method == "owned") {
          Owned(window_, id, result);
        } else if (method == "buy") {
          Buy(window_, id, result);
        } else {
          result->NotImplemented();
        }
      });
}
