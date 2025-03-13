/// A pipeline is used to interact with the scraped data
abstract class Pipeline<InputType> {
  /// Called when the crawler has sent data of type [InputType]
  Future<void> receiveData(InputType data);

  /// Called when the crawler is done
  Future<void> clean();
}
