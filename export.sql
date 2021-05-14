copy (
    select
        h.tsn,
        h.parent_tsn,
        l.completename as complete_name,
        h.level,
        k.kingdom_name,
        coalesce(max(v.vernacular_name), l.completename) as vernacular_name,
        tut.rank_name as type
    from hierarchy h
             inner join longnames l on h.tsn = l.tsn
             left join vernaculars v on l.tsn = v.tsn
             inner join taxonomic_units tu on h.tsn = tu.tsn
             inner join taxon_unit_types tut on tu.kingdom_id = tut.kingdom_id and tu.rank_id = tut.rank_id
             inner join kingdoms k on tu.kingdom_id = k.kingdom_id
    where (v.language = 'English' or v.language is null)
    group by h.tsn, h.level, h.parent_tsn, h.tsn, l.completename, k.kingdom_name, tut.rank_name
) to '/tmp/taxonomy.csv' with csv header;
