//reset & load

MATCH (n)
DETACH DELETE n;

// create indexes
DROP INDEX tax_id IF EXISTS;
CREATE INDEX tax_id FOR (tax:Taxonomy) ON (tax.tsn);
DROP INDEX parent_tax_id IF EXISTS;
CREATE INDEX parent_tax_id FOR (tax:Taxonomy) ON (tax.parent_tsn);
DROP INDEX type_id IF EXISTS;
CREATE INDEX type_id FOR (tax:Taxonomy) ON (tax.type);
DROP INDEX complete_name_id IF EXISTS;
CREATE INDEX complete_name_id FOR (tax:Taxonomy) ON (tax.complete_name);
DROP INDEX vernacular_name_id IF EXISTS;
CREATE INDEX vernacular_name_id FOR (tax:Taxonomy) ON (tax.vernacular_name);

// load data
LOAD CSV WITH HEADERS FROM 'file:///taxonomy.csv' as row
MERGE (tax:Taxonomy {tsn: toInteger(row.tsn)})

SET 
    tax.parent_tsn = toInteger(row.parent_tsn),
    tax.complete_name = trim(row.complete_name),
    tax.vernacular_name = trim(row.vernacular_name),
    tax.kingdom_name = trim(row.kingdom_name),
    tax.level = toInteger(row.level),
    tax.type = trim(row.type)
;

// set labels based on taxonomy type
MATCH (tax:Taxonomy)
CALL apoc.create.addLabels( tax, [ tax.type ] )
YIELD node
RETURN node
;

//relationships
MATCH (child:Taxonomy), (parent:Taxonomy)
WHERE child.parent_tsn = parent.tsn
MERGE (child)-[:IS_IN]->(parent)
;
