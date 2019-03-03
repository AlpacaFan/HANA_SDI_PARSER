# HANA_SDI_PARSER
ANTLR 4 Parser for HANA Syntax for use when writing SDI adapters

The HANA SDI Adapter SDK includes a parser but unfortunately it does not support advanced functionality that can exposed within SDI. This project is intended as a replacement open source parser to write adapters that can parse more advanced SQL.

Feel free to copy and modify this to built your own advanced SDI adapters.

I am doing this as a hobby, mostly because of my frustration that HANA does not support push-down of windowing functions to data sources which is very helpful when connecting to data lakes to obtain the correct version of a row where multiple versions exists. HANA adapters default behavior cause the data to all data to be transfered to HANA where the correct version is chosen which is very, very inefficient especially on large data lakes. The alternative is to write the queries in the data lake (e.g. HIVE/Impala/Teradata) but this is a very inefficient workflow and might not be possible depending on the organisational structure.

