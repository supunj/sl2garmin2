select
	count(*)
from
	nodes
where
	tags @> '"amenity"=>"place_of_worship"' :: hstore
	and tags @> '"religion"=>"buddhist"' :: hstore 

	
select
	tags->'amenity'
from
	nodes
where
	tags ? 'amenity' 	


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
	
select
	tags->'natural',
	count(id) as how_many
from
	nodes
where
	tags notnull
	and tags ? 'natural'
group by
	tags->'natural'
order by
	how_many desc
	
select
	tags->'power',
	count(id) as how_many
from
	nodes
where
	tags notnull
	and tags ? 'power'
group by
	tags->'power'
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
	
	
	
	
select
	tags->'highway',
	count(id) as how_many
from
	nodes
where
	tags notnull
	and tags ? 'highway'
group by
	tags->'highway'
order by
	how_many desc

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
	
	
select *
from ways w 
where w.tags @> '"natural"=>"waterfall"' :: hstore



select
	w.tags -> 'highway',
	count(*) as cnt,
	round(avg(case when w.tags -> 'maxspeed' ~ '^[0-9\.]+$' then cast(w.tags -> 'maxspeed' as INTEGER) else 0 end))
from
	ways w
where
	w.tags ? 'highway'
group by
	w.tags -> 'highway'
order by
	cnt desc
	

select
	avg(cast(w.tags -> 'maxspeed' as INTEGER))
from
	ways w
where
	w.tags @> '"highway"=>"motorway"' :: hstore

	
	select '12.41212' ~ '^[0-9\.]+$'
	
	
select
	*
from
	ways w
where
	w.tags @> '"highway"=>"trunk"' :: hstore
	
	
select *
from relations r 
where r.tags ? 'landuse'

select
	tags->'landuse',
	count(id) as how_many
from
	relations
where
	tags ? 'landuse'
group by
	tags -> 'landuse'
order by
	how_many desc

	
select
	tags->'natural',
	count(id) as how_many
from
	relations
where
	tags ? 'natural'
group by
	tags -> 'natural'
order by
	how_many desc
	

select *
from ways w 
where w.id = 682698483