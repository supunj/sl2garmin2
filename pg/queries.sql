select
	tags->'shop',
	count(id) as how_many
from
	nodes
where
	tags notnull
	and tags ? 'shop'
group by
	tags->'shop'
order by
	how_many desc
	
select *
from nodes
where tags @> '"waterway"=>"waterfall"' :: hstore

select *
from nodes
where tags @> '"natural"=>"waterfall"' :: hstore


select
	tl.key,
	count(*) as cnt
from
	(
	select
		(each(n.tags)).*
	from
		nodes n ) tl
group by
	tl.key
order by
	cnt desc
	
select
	*
from
	(
	select
		(each(n.tags)).*
	from
		nodes n) tgs
where
	tgs.value = 'waterfall'
	
	
select
	*
from
	(
	select
		(each(n.tags)).*
	from
		nodes n) tgs
where
	tgs.value = 'ruins'
	
select
	*
from
	(
	select
		(each(n.tags)).*
	from
		nodes n) tgs
where
	tgs.value = 'grocery'
	
	
	
	
SELECT tags->'amenity', count(id) as how_many
FROM nodes
where tags notnull and tags ? 'amenity'
group by tags->'amenity'
order by how_many desc

select
	tags->'place',
	tags->'amenity',
	count(id) as how_many
from
	nodes
where
	tags notnull
	and tags ? 'place' or tags ? 'amenity'
group by
	tags->'place', tags->'amenity'
order by
	how_many desc
	
select tags 
from nodes n 
group by tags ? * 

select
	tags->'amenity',
	count(id) as how_many
from
	nodes
where
	tags notnull
	and tags ? 'amenity'
group by
	tags->'amenity'
order by
	how_many desc


select
	n.id
from
	nodes n
where
	n.tags notnull
	and n.id not in (
	select
		distinct wn.node_id
	from
		way_nodes wn)
		
		
select
	tl.key,
	count(*) as cnt
from
	(
	select
		(each(n.tags)).*
	from
		nodes n ) tl
group by
	tl.key
order by
	cnt desc