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

export 'src/scrapers/e_commerce/e_commerce_crawler.dart'
    show ECommerceCrawler, ECommerceCrawlerSelectors;

export 'src/scrapers/e_commerce/items/e_commerce_basic.dart'
    show EcommerceItem, ECommerceClothe;

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

// Collectors

export 'src/collectors/navbar_collector.dart' show NavbarCollector;
export 'src/collectors/pagination_collector.dart' show PaginationCollector;
