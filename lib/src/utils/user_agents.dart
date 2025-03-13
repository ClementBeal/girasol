/// Generate an user agent that mimicks the ones from the browser
///
/// Some websites have a security that deny the access to their pages
/// if the user agent is not the one of a famous browser
Map<String, String> fakeUserAgent() {
  return {
    "User-Agent":
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/118.0.0.0 Safari/537.36",
  };
}
