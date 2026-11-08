/// Sticky Wall's pages on the studio website. Google Play and the Google
/// sign-in consent screen (Drive sync) link the English ones, so these
/// addresses must stay stable. Vietnamese gets the `/vi/` copy, every other
/// language the English one.
library;

const _site = 'https://winka.top';

String _lang(String languageCode) => languageCode == 'vi' ? 'vi' : 'en';

Uri _page(String languageCode, String path) =>
    Uri.parse('$_site/${_lang(languageCode)}/$path');

Uri privacyPolicyUri(String languageCode) =>
    _page(languageCode, 'apps/sticky-wall/privacy/');

Uri termsOfServiceUri(String languageCode) =>
    _page(languageCode, 'apps/sticky-wall/terms/');

Uri dataDeletionUri(String languageCode) =>
    _page(languageCode, 'apps/sticky-wall/data-deletion/');

Uri supportUri(String languageCode) =>
    _page(languageCode, 'support/sticky-wall/');
