use ig_clone;

-- objective questions
-- 1. are there any tables with duplicate or missing null values? if so, how would you handle them?

select * from users;
select username, count(*) as count from users
group by username having count(*) > 1;
select distinct * from users; -- no duplicates

select * from photos;
select id, count(*) as count from photos
group by id having count(*) > 1; 
select distinct * from photos; -- no duplicates

select * from comments;
select id, count(*) from comments group by id having count(*) > 1;
select distinct * from comments; -- no duplicates

select * from likes;
select user_id, photo_id, created_at, count(*) as count
from likes
group by user_id, photo_id, created_at
having count(*) > 1; -- no duplicates 

select * from follows;
select follower_id, followee_id, created_at, count(*) as count from follows 
group by follower_id, followee_id, created_at
having count(*) > 1; -- no duplicates

select * from tags;
select id, count(*) as count from tags 
group by id having count(*) > 1; -- no duplicates

select * from photo_tags;
select photo_id, tag_id, count(*) as count from photo_tags
group by photo_id, tag_id having count(*) > 1; -- no duplicates

-- 02. what is the distribution of user activity levels (e.g., number of posts, likes, comments) across the user base?

select u.id as user_id, u.username,
    count(distinct p.id) as num_posts,
    count(distinct l.photo_id) as num_likes,
    count(distinct c.id) as num_comments
from users u
left join photos p on u.id = p.user_id
left join likes l on u.id = l.user_id
left join comments c on u.id = c.user_id
group by u.id, u.username
limit 20;

-- 03. calculate the average number of tags per post (photo_tags and photos tables)

select avg(tags) as avg_tags_per_post 
from (
    select p.id, count(t.tag_id) as tags from photos p 
    left join photo_tags t on p.id = t.photo_id
    group by p.id
) as num_tags;

-- 04. identify the top users with the highest engagement rates (likes, comments) on their posts and rank them.

select
    u.id,
    u.username,
    count(distinct l.user_id) as num_likes,
    count(distinct c.id) as num_comments,
    (count(distinct l.user_id) + count(distinct c.id)) / nullif(count(p.id), 0) as engagement_rate,
    rank() over (order by (count(distinct l.user_id) + count(distinct c.id)) / nullif(count(p.id), 0) desc) as 'rank'
from users u
join photos p on u.id = p.user_id
left join likes l on p.id = l.photo_id
left join comments c on p.id = c.photo_id
group by u.id, u.username
order by 'rank'
limit 20;

-- 05. which users have the highest number of followers and followings?

select 
    u.id,
    u.username,
    count(distinct f.follower_id) as num_followers,
    count(distinct ff.followee_id) as num_followings
from users u
left join follows f on u.id = f.followee_id
left join follows ff on u.id = ff.follower_id
group by u.id, u.username
order by num_followers desc, num_followings desc;

-- 06. calculate the average engagement rate (likes, comments) per post for each user.

select 
    u.id,
    u.username,
    count(p.id) as total_photos,
    avg(coalesce(l.likes_count, 0) + coalesce(c.comments_count, 0)) as avg_engagement_rate
from 
    users u
join 
    photos p on u.id = p.user_id
left join 
    (select photo_id, count(*) as likes_count from likes group by photo_id) l on p.id = l.photo_id
left join 
    (select photo_id, count(*) as comments_count from comments group by photo_id) c on p.id = c.photo_id
group by 
    u.id, u.username
order by 
    avg_engagement_rate desc
limit 20;

-- 07. get the list of users who have never liked any post (users and likes tables)

select u.id, u.username
from users u
where u.id not in (select l.user_id from likes l);

-- 08. how can you leverage user-generated content (posts, hashtags, photo tags) to create more personalized and engaging ad campaigns?

select 
    u.id as user_id,
    u.username,
    p.id as post_id,
    p.image_url,
    p.created_dat as created_date,
    count(l.user_id) as likes_count,
    count(c.id) as comments_count
from 
    users u
join 
    photos p on u.id = p.user_id
left join 
    likes l on p.id = l.photo_id
left join 
    comments c on p.id = c.photo_id
group by 
    u.id, u.username, p.id, p.image_url, p.created_dat
limit 20;

-- 09. are there any correlations between user activity levels and specific content types (e.g., photos, videos, reels)? how can this information guide content creation and curation strategies?

select 
    u.id as user_id,
    u.username,
    count(p.id) as total_photos,
    coalesce(sum(l.likes_count), 0) as total_likes,
    coalesce(sum(c.comments_count), 0) as total_comments,
    avg(coalesce(l.likes_count, 0) + coalesce(c.comments_count, 0)) as avg_engagement_per_post
from 
    users u
join 
    photos p on u.id = p.user_id
left join 
    (select photo_id, count(*) as likes_count from likes group by photo_id) l on p.id = l.photo_id
left join 
    (select photo_id, count(*) as comments_count from comments group by photo_id) c on p.id = c.photo_id
group by 
    u.id, u.username
order by 
    avg_engagement_per_post desc
limit 30;

-- 10. calculate the total number of likes, comments, and photo tags for each user.

select 
    u.id as user_id,
    u.username,
    count(l.user_id) as total_likes,
    count(c.id) as total_comments,
    count(pt.tag_id) as total_photo_tags
from 
    users u
join 
    photos p on u.id = p.user_id
left join 
    likes l on p.id = l.photo_id
left join 
    comments c on p.id = c.photo_id
left join 
    photo_tags pt on p.id = pt.photo_id
group by 
    u.id, u.username
order by 
    u.username;

-- 11. rank users based on their total engagement (likes, comments, shares) over a month.

with engagement as (
    select 
        u.id,
        count(l.user_id) as total_engagement
    from 
        users u
    left join 
        likes l on u.id = l.user_id
    group by 
        u.id
)
select 
    id,
    total_engagement,
    row_number() over (order by total_engagement desc) as engagement_rank
from 
    engagement
order by 
    engagement_rank;

-- 12. retrieve the hashtags that have been used in posts with the highest average number of likes. use a cte to calculate the average likes for each hashtag first.

with hashtag_likes as (
  select 
    t.tag_name,
    avg(l.likes) as avg_likes
  from 
    photo_tags pt
  join 
    tags t on pt.tag_id = t.id
  join 
    (select photo_id, count(*) as likes from likes group by photo_id) l on pt.photo_id = l.photo_id
  group by 
    t.tag_name
)
select 
  tag_name,
  round(avg_likes, 2) as avg_likes
from 
  hashtag_likes
order by 
  avg_likes desc;
    
    

-- 13. retrieve the users who have started following someone after being followed by that person.

select 
    f1.follower_id as user_id,
    f1.followee_id as followee_id,
    f1.created_at as follow_time
from 
    follows f1
where 
    exists (
        select 
            1
        from 
            follows f2
        where 
            f2.follower_id = f1.followee_id
            and f2.followee_id = f1.follower_id
            and f2.created_at < f1.created_at
    );

-- subjective questions

-- 01. based on user engagement and activity levels, which users would you consider the most loyal or valuable? how would you reward or incentivize these users?

select u.id as user_id, u.username,
       count(distinct p.id) as total_posts,
       count(distinct c.id) as total_comments,
       count(distinct l.photo_id) as total_likes
from users u
left join photos p on u.id = p.user_id
left join comments c on u.id = c.user_id
left join likes l on u.id = l.user_id
group by u.id
order by total_posts desc, total_comments desc, total_likes desc
limit 10;

-- 02. for inactive users, what strategies would you recommend to re-engage them and encourage them to start posting or engaging again?

select u.id as user_id, u.username
from users u
left join photos p on u.id = p.user_id and p.created_dat >= now() 
left join comments c on u.id = c.user_id and c.created_at >= now() 
left join likes l on u.id = l.user_id and l.created_at >= now() 
left join follows f on u.id = f.follower_id and f.created_at >= now() 
where p.id is null and c.id is null and l.photo_id is null and f.followee_id is null
order by u.created_at;

-- 03. which hashtags or content topics have the highest engagement rates? how can this information guide content strategy and ad campaigns?

with hashtag_engagement as (
  select 
    t.tag_name,
    sum(l.photo_id) as total_likes,
    sum(c.id) as total_comments,
    count(pt.photo_id) as num_posts,
    (sum(l.photo_id) + sum(c.id)) / count(pt.photo_id) as engagement_rate
  from 
    photo_tags pt
  join 
    tags t on pt.tag_id = t.id
  left join 
    likes l on pt.photo_id = l.photo_id
  left join 
    comments c on pt.photo_id = c.photo_id
  group by 
    t.tag_name
)
select 
  tag_name,
  total_likes,
  total_comments,
  num_posts,
  engagement_rate
from 
  hashtag_engagement
order by 
  engagement_rate desc;

-- 04. are there any patterns or trends in user engagement based on demographics (age, location, gender) or posting times? how can these insights inform targeted marketing campaigns?

select 
    u.id,
    count(l.user_id) as likes_count,
    count(c.id) as comments_count,
    count(f.follower_id) as follows_count
from 
    users u
left join 
    likes l on u.id = l.user_id
left join 
    comments c on u.id = c.user_id
left join 
    follows f on u.id = f.follower_id
group by 
    u.id
limit 20;

-- 05. based on follower counts and engagement rates, which users would be ideal candidates for influencer marketing campaigns? how would you approach and collaborate with these influencers?

with user_engagement as (
  select 
    u.id,
    u.username,
    count(f.follower_id) as followers,
    sum(l.likes) as likes,
    sum(c.comments) as comments,
    (sum(l.likes) + sum(c.comments)) / count(f.follower_id) as engagement_rate
  from 
    users u
  left join 
    follows f on u.id = f.followee_id
  left join 
    (select photo_id, count(*) as likes from likes group by photo_id) l on l.photo_id in (select id from photos where user_id = u.id)
  left join 
    (select photo_id, count(*) as comments from comments group by photo_id) c on c.photo_id in (select id from photos where user_id = u.id)
  group by 
    u.id, u.username
)
select 
  *
from 
  user_engagement
where 
  followers > 1000 and engagement_rate > 0.05;

-- 06. based on user behavior and engagement data, how would you segment the user base for targeted marketing campaigns or personalized recommendations?

select 
    u.id,
    u.username,
    count(l.user_id) as likes_count,
    count(c.id) as comments_count,
    count(f.follower_id) as follows_count,
    case 
        when count(l.user_id) + count(c.id) + count(f.follower_id) > 10 then 'power user'
        when count(l.user_id) + count(c.id) + count(f.follower_id) between 5 and 10 then 'active user'
        else 'inactive user'
    end as user_segment
from 
    users u
left join 
    likes l on u.id = l.user_id
left join 
    comments c on u.id = c.user_id
left join 
    follows f on u.id = f.follower_id
group by 
    u.id;

-- 07. if data on ad campaigns (impressions, clicks, conversions) is available, how would you measure their effectiveness and optimize future campaigns?

select 
    ac.id,
    ac.name,
    count(i.id) as impressions,
    count(c.id) as clicks,
    count(cv.id) as conversions,
    (count(cv.id) / count(i.id)) * 100 as conversion_rate
from 
    ad_campaigns ac
join 
    impressions i on ac.id = i.ad_campaign_id
left join 
    clicks c on i.id = c.impression_id
left join 
    conversions cv on c.id = cv.click_id
group by 
    ac.id;

-- 08. how can you use user activity data to identify potential brand ambassadors or advocates who could help promote instagram's initiatives or events?

select 
    u.id as user_id, 
    u.username,
    count(distinct p.id) as total_posts, 
    count(distinct c.id) as total_comments,
    count(distinct l.photo_id) as total_likes,
    count(distinct f.follower_id) as total_followers, 
    (count(distinct l.photo_id) + count(distinct c.id)) / count(distinct p.id) as engagement_rate,
    group_concat(distinct t.tag_name) as hashtags_used, 
    case 
        when count(distinct p.id) > 20 and (count(distinct l.photo_id) + count(distinct c.id)) / count(distinct p.id) > 0.2 then 'high engagement user'
        when count(distinct f.follower_id) > 1000 and (count(distinct l.photo_id) + count(distinct c.id)) / count(distinct p.id) > 0.1 then 'potential influencer'
        when group_concat(distinct t.tag_name) like '%#instagram%' or group_concat(distinct t.tag_name) like '%#event%' then 'event advocate'
        else 'other'
    end as user_segment
from users u
left join photos p on u.id = p.user_id
left join comments c on u.id = c.user_id
left join likes l on u.id = l.user_id
left join follows f on u.id = f.followee_id
left join photo_tags pt on p.id = pt.photo_id
left join tags t on pt.tag_id = t.id
group by u.id
having total_followers > 500 and engagement_rate > 0.1  
order by total_followers desc, engagement_rate desc
limit 10;

-- 10. assuming there's a "user_interactions" table tracking user engagements, how can you update the "engagement_type" column to change all instances of "like" to "heart" to align with instagram's terminology?

select 
    u.id as user_id,
    u.username,
    count(distinct p.id) as total_posts,
    count(distinct l.photo_id) as total_likes,
    count(distinct c.id) as total_comments,
    count(distinct f.follower_id) as total_conversions,
    (count(distinct l.photo_id) + count(distinct c.id)) / count(distinct p.id) as engagement_rate
from users u
left join photos p on u.id = p.user_id
left join likes l on p.id = l.photo_id
left join comments c on p.id = c.photo_id
left join follows f on u.id = f.followee_id
group by u.id
having total_posts > 10
   and total_likes + total_comments > 100
order by engagement_rate desc
limit 10;


-- ------------------------------------------------------------------------------------------------------------------
-- Monthly Retention Trends
select 
    date_format(created_at, '%Y-%m') as month,
    count(id) as new_users
from 
    users
group by 
    date_format(created_at, '%Y-%m')
order by 
    month;


-- Most Used Tags
select 
    tags.tag_name, 
    count(photo_tags.photo_id) as usage_count
from 
    tags
join 
    photo_tags on tags.id = photo_tags.tag_id
group by 
    tags.tag_name
order by 
    usage_count desc;




