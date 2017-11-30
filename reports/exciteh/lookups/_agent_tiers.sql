SET search_path to lookups,public
;
truncate table agent_tiers
;
insert into agent_tiers
select x.id_agent,y.tier,z.agent_enabled 
from (
	select distinct id_agent from agents
) x
left join (
	select a.id_agent,c.name as tier
	from agents a
	left join agent_roles b on a.id_agent=b.id_agent
	left join roles c on b.id_role=c.id_role
) y using(id_agent)

left join (
	select id_agent,
	(clients.status = 1 AND clients.status IS NOT NULL)	AS agent_enabled
	from agents
	join clients using(id_client)
) z using(id_agent)
;
select id_agent,count(*) from agent_tiers
group by 1
having count(*) > 1
;
--tiers missing:>0
select * from tableau_bookings 
where id_agent not in (select id_agent from agent_tiers)
limit 100
