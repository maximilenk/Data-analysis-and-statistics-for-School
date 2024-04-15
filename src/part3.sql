
-- wellpetr

create function successfull_check(check_id bigint) returns BIGINT AS $$
BEGIN
IF (check_id IN (select check_ from p2p where state = 'success') AND
    (check_id IN (select check_ from verter where verter.state = 'success') OR
    check_id NOT IN (select check_ from verter))) then
    RETURN 1;
ELSE
    RETURN 0;
END IF;
END;
$$ LANGUAGE PLPGSQL; -- helper function

-- 1
create function points_readable() returns table (Peer1 varchar, Peer2 varchar, points numeric) AS $$
SELECT tp1.checkingpeer AS Peer1, tp1.checkedpeer AS Peer2, SUM(tp1.pointsamount) - SUM(tp2.pointsamount)
FROM transferredpoints tp1
LEFT JOIN transferredpoints tp2 ON tp2.checkingpeer = tp1.checkedpeer AND tp2.checkedpeer = tp1.checkingpeer
GROUP BY (Peer1, Peer2)
ORDER BY Peer1;
$$ LANGUAGE SQL;

select * from points_readable();

-- 2
create function xp_for_task() returns table (Peer varchar, Task varchar, XP numeric) AS $$
SELECT checks.peer, checks.task, xp.xpamount as xp
FROM checks
RIGHT JOIN xp ON xp.check_ = checks.id
ORDER BY Peer;
$$ LANGUAGE SQL;

select * from xp_for_task();

-- 3
create function havent_left(day date) returns table (Peer varchar) AS $$
SELECT peer
FROM timetracking tr
WHERE tr.date = day
GROUP BY peer
HAVING COUNT(CASE state WHEN 2 THEN 1 ELSE NULL END) < 2
ORDER BY Peer;
$$ LANGUAGE SQL;

select * from havent_left('2023-11-03');

-- 4
create function change() returns table (Peer varchar, PointsChange numeric) AS $$
SELECT tp1.checkingpeer AS Peer, SUM(tp1.pointsamount) - SUM(tp2.pointsamount)
FROM transferredpoints tp1
LEFT JOIN transferredpoints tp2 ON tp2.checkedpeer = tp1.checkingpeer AND tp2.checkingpeer = tp1.checkedpeer
GROUP BY Peer
ORDER BY Peer;
$$ LANGUAGE SQL;

select * from change();

-- 5
create function change2() returns table (Peer varchar, PointsChange numeric) AS $$
SELECT Peer1 AS Peer, SUM(points)
FROM points_readable()
GROUP BY Peer
ORDER BY Peer;
$$ LANGUAGE SQL;

select * from change2();

-- 6
create function pop_task() returns table (day date, task varchar) AS $$
SELECT date as day, task
FROM checks ch1
GROUP BY day, task
HAVING count(task) = (SELECT count(task)
        FROM checks ch2
        WHERE ch1.date = ch2.date
        GROUP BY ch2.date, task
        ORDER BY count(task) DESC
        LIMIT 1)
ORDER BY day;
$$ LANGUAGE SQL;

select * from pop_task();

-- 7
create function completed(block varchar) returns table (peer varchar, date date) AS $$
BEGIN
block := '^' || block || '[0-9]';
RETURN QUERY
WITH cte AS (
SELECT parenttask
FROM tasks
WHERE title ~ block)
SELECT ch.peer, ch.date
FROM checks ch
WHERE task IN (
SELECT title
FROM tasks t
WHERE title ~ block AND NOT EXISTS (SELECT ParentTask
                FROM cte
                WHERE t.title = cte.parenttask)) AND successfull_check(ch.id) = 1;
END;
$$ LANGUAGE PLPGSQL;

select * from completed('C');

-- 8
create function recommendations() returns table (peer varchar, RecommendedPeer varchar) AS $$
WITH cte AS (
SELECT nickname, recommendedpeer
FROM peers
LEFT JOIN recommendations rc ON rc.peer IN (SELECT peer2
                FROM friends
                WHERE peer1 = nickname) AND rc.recommendedpeer != nickname)
SELECT DISTINCT nickname, recommendedpeer
FROM cte
WHERE recommendedpeer = (SELECT recommendedpeer
                        FROM cte c2
                        WHERE cte.nickname = c2.nickname
                        GROUP BY recommendedpeer
                        ORDER BY COUNT(recommendedpeer) DESC, recommendedpeer ASC
                        LIMIT 1)
ORDER BY nickname;
$$ LANGUAGE SQL;

select * from recommendations();

-- 9
create function percentages(block1 varchar, block2 varchar) returns table (startedblock1 float, startedblock2 float, 
    startedbothblocks float, didntstartanyblock float) AS $$
DECLARE
total numeric := (SELECT COUNT(id) FROM peers);
one numeric;
two numeric;
both_ numeric;
none_ numeric;
BEGIN
block1 := '^' || block1 || '[0-9]';
block2 := '^' || block2 || '[0-9]';
one := (SELECT COUNT(DISTINCT peer) FROM checks WHERE task ~ block1);
two := (SELECT COUNT(DISTINCT peer) FROM checks WHERE task ~ block2);
both_ := (SELECT COUNT(DISTINCT peer) FROM (SELECT peer FROM checks WHERE task ~ block1
                        INTERSECT
                        SELECT peer FROM checks WHERE task ~ block2) b);
none_ := (SELECT COUNT (DISTINCT peer) FROM
                        (SELECT nickname AS peer FROM peers
                        EXCEPT
                        (SELECT peer FROM checks WHERE task ~ block1
                        UNION
                        SELECT peer FROM checks WHERE task ~ block2)) n);
RETURN QUERY SELECT round((one/total::float)*100), 
        round((two/total::float)*100), 
        round((both_/total::float)*100), 
        round((none_/total::float)*100);
END;
$$ LANGUAGE PLPGSQL;

select * from percentages('CPP', 'SQL');

-- steinbrp

-- procedure 10
CREATE OR REPLACE PROCEDURE birthday_review(ref refcursor)
LANGUAGE plpgsql
AS $$
BEGIN
    OPEN ref FOR
        WITH cte (SuccessfulChecks) AS (
            SELECT COUNT(p.id)
            FROM peers p
            JOIN checks ch ON to_char(ch.date, 'mon-dd') = to_char(p.birthday, 'mon-dd')
            JOIN xp ON xp.check_ = ch.id),
        cte2 (UnSuccessfulChecks) AS (
            SELECT COUNT(p.id)
            FROM peers p
            JOIN checks ch ON to_char(ch.date, 'mon-dd') = to_char(p.birthday, 'mon-dd')
            LEFT JOIN xp ON xp.check_ = ch.id
            WHERE xp.check_ IS NULL)
        SELECT round(100 * cte.SuccessfulChecks /
                     (CASE cte.SuccessfulChecks + cte2.UnSuccessfulChecks
                         WHEN 0 THEN 1
                         ELSE cte.SuccessfulChecks + cte2.UnSuccessfulChecks
                         END)) as SuccessfulChecks,
               round(100 * cte2.UnSuccessfulChecks /
                     (CASE cte.SuccessfulChecks + cte2.UnSuccessfulChecks
                         WHEN 0 THEN 1
                         ELSE cte.SuccessfulChecks + cte2.UnSuccessfulChecks
                         END)) as UnSuccessfulChecks
        FROM cte, cte2;
END;
$$;

-- check
BEGIN;
CALL birthday_review('cur_birthday_review');
FETCH ALL IN cur_birthday_review;
CLOSE cur_birthday_review;
COMMIT;

-- procedure 11
CREATE OR REPLACE PROCEDURE made_three_tasks(
    Task1 varchar,
    Task2 varchar,
    Task3 varchar,
    ref refcursor
)
LANGUAGE plpgsql
AS $$
BEGIN
    OPEN ref FOR
        WITH made_first_task AS (
            SELECT p.nickname
            FROM peers p
            JOIN checks ch ON p.nickname = ch.peer
            JOIN xp ON ch.id = xp.check_
            WHERE ch.task = Task1),
        made_second_task AS(
            SELECT p.nickname
            FROM peers p
            JOIN checks ch ON p.nickname = ch.peer
            JOIN xp ON ch.id = xp.check_
            WHERE ch.task = Task2),
        doesnt_make_third_task AS (
            SELECT p.nickname
            FROM peers p
            JOIN checks ch ON p.nickname = ch.peer
            LEFT JOIN xp ON ch.id = xp.check_
            WHERE ch.task = Task3 AND xp.check_ IS NULL
            UNION
            SELECT p.nickname
            FROM peers p
            WHERE (SELECT id
                   FROM checks
                   WHERE checks.peer = p.nickname
                     AND checks.task = Task3
                    LIMIT 1) is NULL)
        SELECT *
        from made_first_task
        INTERSECT
        SELECT *
        FROM made_second_task
        INTERSECT
        SELECT *
        FROM doesnt_make_third_task;
END;
$$;

-- checks
BEGIN;
CALL made_three_tasks(
    'C8_3DViewer',
    'CPP2_Containers',
    'SQL1_Info21',
    'cur_made_three_tasks');
FETCH ALL IN cur_made_three_tasks;
CLOSE cur_made_three_tasks;
COMMIT;

BEGIN;
CALL made_three_tasks(
    'C8_3DViewer',
    'CPP1_Matrix',
    'CPP2_Containers',
    'cur_made_three_tasks');
FETCH ALL IN cur_made_three_tasks;
CLOSE cur_made_three_tasks;
COMMIT;

-- procedure 12
CREATE OR REPLACE PROCEDURE previous_tasks(ref refcursor)
LANGUAGE plpgsql
AS $$
BEGIN
    OPEN ref FOR
        WITH RECURSIVE number_of_tasks AS (
            SELECT t.title, t.parenttask, 0 AS n
            FROM tasks t
            WHERE t.parenttask = ''
            UNION ALL
            SELECT t.title, t.parenttask, n + 1
            FROM tasks t
            INNER JOIN number_of_tasks ON number_of_tasks.title = t.parenttask
        )
        SELECT title AS TASK, n AS PrevCount
        FROM number_of_tasks;
END;
$$;

-- check
BEGIN;
CALL previous_tasks('cur_prev_tasks');
FETCH ALL IN cur_prev_tasks;
CLOSE cur_prev_tasks;
COMMIT;

-- procedure 13
CREATE OR REPLACE PROCEDURE lucky_days(
    successReview bigint,
    ref refcursor
)
LANGUAGE plpgsql
AS $$
BEGIN
    OPEN ref FOR
        WITH review AS (
            SELECT ch.id,
                   ch.date,
                   p2p.time,
                   (CASE
                       WHEN (SELECT xp.id
                             FROM xp
                             WHERE xp.check_ = ch.id
                               AND xp.xpamount >= (SELECT t.maxxp
                                                    FROM tasks t
                                                    WHERE ch.task = t.title) * 0.8) IS NOT NULL THEN 'success'
                       ELSE 'failure'
                    END) AS status
            from checks ch
            JOIN p2p on ch.id = p2p.check_
            WHERE p2p.state = 'start'
            ORDER BY 2, 3
        ),
        success AS (
            SELECT id, date, time,
                   (CASE
                       WHEN status = 'success'
                       THEN row_number() OVER (PARTITION BY date, status)
                       ELSE 0
                    END) AS number,
                   status
            FROM review
            ORDER BY 2, 3
        )
        SELECT date, MAX(number) FROM success GROUP BY date HAVING MAX(number) >= successReview;
END;
$$;

-- check
BEGIN;
CALL lucky_days(2, 'cur_lucky_days');
FETCH ALL IN cur_lucky_days;
CLOSE cur_lucky_days;
COMMIT;

--procedure 14
CREATE OR REPLACE PROCEDURE max_xp(
    ref refcursor
)
LANGUAGE plpgsql
AS $$
BEGIN
    OPEN ref FOR
    SELECT p.nickname, SUM(xp.xpamount)
    FROM peers p
    JOIN checks ch  ON ch.peer = p.nickname
    JOIN xp  ON xp.check_ = ch.id
    GROUP BY p.nickname
    ORDER BY 2 DESC
    LIMIT 1;
END;
$$;

-- check
BEGIN;
CALL max_xp('cur_max_xp');
FETCH ALL IN cur_max_xp;
CLOSE cur_max_xp;
COMMIT;

-- procedure 15
CREATE OR REPLACE PROCEDURE early_entrance(
    entranceTime time,
    entrance bigint,
    ref refcursor
)
LANGUAGE plpgsql
AS $$
BEGIN
    OPEN ref FOR
    SELECT peer
    FROM timetracking t
    WHERE state = 1
      AND time < entranceTime
    GROUP BY peer
    HAVING count(id) >= entrance;
END;
$$;

--checks
BEGIN;
CALL early_entrance('20:00:00', 1, 'cur_early_entrance');
FETCH ALL IN cur_early_entrance;
CLOSE cur_early_entrance;
COMMIT;

BEGIN;
CALL early_entrance('13:00:00', 2, 'cur_early_entrance');
FETCH ALL IN cur_early_entrance;
CLOSE cur_early_entrance;
COMMIT;

BEGIN;
CALL early_entrance('20:00:00', 4, 'cur_early_entrance');
FETCH ALL IN cur_early_entrance;
CLOSE cur_early_entrance;
COMMIT;

-- procedure 16
CREATE OR REPLACE PROCEDURE exit_last_days(
    days bigint,
    exits bigint,
    ref refcursor
)
LANGUAGE plpgsql
AS $$
BEGIN
    OPEN ref FOR
    SELECT peer
    FROM timetracking  t
    WHERE state = 2
    AND current_timestamp::date - t.date < days
    GROUP BY peer
    HAVING count(id) > exits;
END;
$$;

--check
BEGIN;
CALL exit_last_days(35, 1, 'cur_exit_last_days');
FETCH ALL IN cur_exit_last_days;
CLOSE cur_exit_last_days;
COMMIT;

-- procedure 17
CREATE OR REPLACE PROCEDURE early_entrance_percent(ref refcursor)
LANGUAGE plpgsql
AS $$
BEGIN
    OPEN ref FOR
    WITH birthday_entrance AS (
        SELECT t.date, t.time
        FROM timetracking t
        JOIN peers p ON to_char(p.birthday, 'MM') = to_char(t.date, 'MM')
        WHERE t.state = 1
    ),
    all_month AS (
        SELECT to_char(year, 'month') AS month, 0 as EarlyEntries
        FROM generate_series('2023-01-31'::Date, '2023-12-31'::date, '1 month') AS year
    )
    SELECT am.month,
           (CASE
               WHEN (
               SELECT count(*)
               from birthday_entrance be
               WHERE to_char(be.date, 'month') = am.month) != 0
                   THEN 100 * (
                   SELECT count(*)
                   from birthday_entrance be
                   WHERE to_char(be.date, 'month') = am.month
                     AND time < '12:00:00') / (
                     SELECT count(*)
                     from birthday_entrance be
                     WHERE to_char(be.date, 'month') = am.month)
               ELSE am.EarlyEntries
            END) AS EarlyEntries
    FROM all_month am;
END;
$$;

--check
BEGIN;
CALL early_entrance_percent('cur_early_entrance_percent');
FETCH ALL IN cur_early_entrance_percent;
CLOSE cur_early_entrance_percent;
COMMIT;
