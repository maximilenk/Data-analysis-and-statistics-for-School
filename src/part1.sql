-- create database info21;

-- \c info21;
-- ^for psql, otherwise create database manually

create table Peers
    (id bigint primary key,
    Nickname varchar,
    Birthday date);

create table Tasks
    (id bigint primary key,
    Title varchar,
    ParentTask varchar,
    MaxXP numeric);

create type check_status as enum ('start', 'success', 'failure');

create table P2P
    (id bigint primary key,
    Check_ bigint,
    CheckingPeer varchar,
    State check_status,
    Time time);

create table Verter
    (id bigint primary key,
    Check_ bigint,
    State check_status,
    Time time);

create table Checks
    (id bigint primary key,
    Peer varchar,
    Task varchar,
    Date date);

create table TransferredPoints
    (id bigint primary key,
    CheckingPeer varchar,
    CheckedPeer varchar,
    PointsAmount numeric);

create table Friends
    (id bigint primary key,
    Peer1 varchar,
    Peer2 varchar);

create table Recommendations
    (id bigint primary key,
    Peer varchar,
    RecommendedPeer varchar);

create table XP
    (id bigint primary key,
    Check_ bigint,
    XPAmount numeric);

create table TimeTracking
    (id bigint primary key,
    Peer varchar,
    Date date,
    Time time,
    State bigint,
    constraint ch_state check (state in (1,2)));

CREATE PROCEDURE import_peers(delim char)
LANGUAGE PLPGSQL
AS $$
BEGIN
execute 'copy Peers from ''/Users/wellpetr/SQL2_Info21_v1.0-1/src/csv/peers.csv'' delimiter ''' || delim || '''';
END;
$$;
CREATE PROCEDURE import_tasks(delim char)
LANGUAGE PLPGSQL
AS $$
BEGIN
execute 'copy tasks from ''/Users/wellpetr/SQL2_Info21_v1.0-1/src/csv/tasks.csv'' delimiter ''' || delim || '''';
END;
$$;
CREATE PROCEDURE import_p2p(delim char)
LANGUAGE PLPGSQL
AS $$
BEGIN
execute 'copy p2p from ''/Users/wellpetr/SQL2_Info21_v1.0-1/src/csv/p2p.csv'' delimiter ''' || delim || '''';
END;
$$;
CREATE PROCEDURE import_verter(delim char)
LANGUAGE PLPGSQL
AS $$
BEGIN
execute 'copy verter from ''/Users/wellpetr/SQL2_Info21_v1.0-1/src/csv/verter.csv'' delimiter ''' || delim || '''';
END;
$$;
CREATE PROCEDURE import_checks(delim char)
LANGUAGE PLPGSQL
AS $$
BEGIN
execute 'copy checks from ''/Users/wellpetr/SQL2_Info21_v1.0-1/src/csv/checks.csv'' delimiter ''' || delim || '''';
END;
$$;
CREATE PROCEDURE import_transferredpoints(delim char)
LANGUAGE PLPGSQL
AS $$
BEGIN
execute 'copy transferredpoints from ''/Users/wellpetr/SQL2_Info21_v1.0-1/src/csv/transferredpoints.csv'' delimiter ''' || delim || '''';
END;
$$;
CREATE PROCEDURE import_friends(delim char)
LANGUAGE PLPGSQL
AS $$
BEGIN
execute 'copy friends from ''/Users/wellpetr/SQL2_Info21_v1.0-1/src/csv/friends.csv'' delimiter ''' || delim || '''';
END;
$$;
CREATE PROCEDURE import_recommendations(delim char)
LANGUAGE PLPGSQL
AS $$
BEGIN
execute 'copy recommendations from ''/Users/wellpetr/SQL2_Info21_v1.0-1/src/csv/recommendations.csv'' delimiter ''' || delim || '''';
END;
$$;
CREATE PROCEDURE import_xp(delim char)
LANGUAGE PLPGSQL
AS $$
BEGIN
execute 'copy xp from ''/Users/wellpetr/SQL2_Info21_v1.0-1/src/csv/xp.csv'' delimiter ''' || delim || '''';
END;
$$;
CREATE PROCEDURE import_timetracking(delim char)
LANGUAGE PLPGSQL
AS $$
BEGIN
execute 'copy timetracking from ''/Users/wellpetr/SQL2_Info21_v1.0-1/src/csv/timetracking.csv'' delimiter ''' || delim || '''';
END;
$$;

CALL import_peers(',');
CALL import_tasks(',');
CALL import_p2p(',');
CALL import_verter(',');
CALL import_checks(',');
CALL import_transferredpoints(',');
CALL import_friends(',');
CALL import_recommendations(',');
CALL import_xp(',');
CALL import_timetracking(',');

CREATE PROCEDURE export_peers(delim char)
LANGUAGE PLPGSQL
AS $$
BEGIN
execute 'copy Peers to ''/Users/wellpetr/SQL2_Info21_v1.0-1/src/csv/peers.csv'' delimiter ''' || delim || '''';
END;
$$;
CREATE PROCEDURE export_tasks(delim char)
LANGUAGE PLPGSQL
AS $$
BEGIN
execute 'copy tasks to ''/Users/wellpetr/SQL2_Info21_v1.0-1/src/csv/tasks.csv'' delimiter ''' || delim || '''';
END;
$$;
CREATE PROCEDURE export_p2p(delim char)
LANGUAGE PLPGSQL
AS $$
BEGIN
execute 'copy p2p to ''/Users/wellpetr/SQL2_Info21_v1.0-1/src/csv/p2p.csv'' delimiter ''' || delim || '''';
END;
$$;
CREATE PROCEDURE export_verter(delim char)
LANGUAGE PLPGSQL
AS $$
BEGIN
execute 'copy verter to ''/Users/wellpetr/SQL2_Info21_v1.0-1/src/csv/verter.csv'' delimiter ''' || delim || '''';
END;
$$;
CREATE PROCEDURE export_checks(delim char)
LANGUAGE PLPGSQL
AS $$
BEGIN
execute 'copy checks to ''/Users/wellpetr/SQL2_Info21_v1.0-1/src/csv/checks.csv'' delimiter ''' || delim || '''';
END;
$$;
CREATE PROCEDURE export_transferredpoints(delim char)
LANGUAGE PLPGSQL
AS $$
BEGIN
execute 'copy transferredpoints to ''/Users/wellpetr/SQL2_Info21_v1.0-1/src/csv/transferredpoints.csv'' delimiter ''' || delim || '''';
END;
$$;
CREATE PROCEDURE export_friends(delim char)
LANGUAGE PLPGSQL
AS $$
BEGIN
execute 'copy friends to ''/Users/wellpetr/SQL2_Info21_v1.0-1/src/csv/friends.csv'' delimiter ''' || delim || '''';
END;
$$;
CREATE PROCEDURE export_recommendations(delim char)
LANGUAGE PLPGSQL
AS $$
BEGIN
execute 'copy recommendations to ''/Users/wellpetr/SQL2_Info21_v1.0-1/src/csv/recommendations.csv'' delimiter ''' || delim || '''';
END;
$$;
CREATE PROCEDURE export_xp(delim char)
LANGUAGE PLPGSQL
AS $$
BEGIN
execute 'copy xp to ''/Users/wellpetr/SQL2_Info21_v1.0-1/src/csv/xp.csv'' delimiter ''' || delim || '''';
END;
$$;
CREATE PROCEDURE export_timetracking(delim char)
LANGUAGE PLPGSQL
AS $$
BEGIN
execute 'copy timetracking to ''/Users/wellpetr/SQL2_Info21_v1.0-1/src/csv/timetracking.csv'' delimiter ''' || delim || '''';
END;
$$;