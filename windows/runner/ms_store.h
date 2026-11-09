#ifndef RUNNER_MS_STORE_H_
#define RUNNER_MS_STORE_H_

#include <flutter/binary_messenger.h>
#include <flutter/encodable_value.h>
#include <flutter/method_channel.h>
#include <windows.h>

#include <memory>

// Sticky Wall Pro through the Microsoft Store (Windows.Services.Store), on
// the "sticky_wall/ms_store" channel. Each call takes the add-on's Product
// ID (its in-app offer token, "sticky_wall_pro"):
//   price -> the store's formatted price, or null when it cannot be found
//   owned -> whether this account owns it, or null when there is no answer
//   buy   -> "purchased", "alreadyPurchased", "notPurchased" or "error"
// See lib/services/ms_store.dart for the Dart side.
class MsStoreChannel {
 public:
  // |window| owns the Store's purchase dialog.
  MsStoreChannel(flutter::BinaryMessenger* messenger, HWND window);

 private:
  std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> channel_;
  HWND window_;
};

#endif  // RUNNER_MS_STORE_H_
