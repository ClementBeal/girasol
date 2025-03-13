library;

export 'src/executor.dart'
    show Girasol, ParseResult, ParsedData, ParsedEmpty, ParsedLink;

// Crawlers export
export 'src/scrapers/scraper.dart'
    show
        WebCrawler,
        StaticWebCrawler,
        CrawlDocument,
        FileDocument,
        HTMLDocument,
        JsonDocument,
        TextDocument;

// Pipelines export
export 'src/pipelines/pipeline.dart' show Pipeline;

export 'src/pipelines/files/file_pipeline.dart' show FilePipeline, FileItem;
export 'src/pipelines/format/csv_pipeline.dart' show CSVPipeline, CsvItem;
export 'src/pipelines/format/json_pipeline.dart' show JSONPipeline, JsonItem;
export 'src/pipelines/format/xml_pipeline.dart' show XMLPipeline, XmlItem;

// HTTP client

export 'src/utils/browser_http_client.dart'
    show BrowserHttpClient, CrawlRequest, CrawlResponse;

export 'package:xml/xml.dart';
export 'package:html/parser.dart';
