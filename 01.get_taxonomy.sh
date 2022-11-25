# description: $1: genbank id
esearch -db nuccore -query $1 | efetch -format docsum |xtract -pattern DocumentSummary -element Extra TaxId
