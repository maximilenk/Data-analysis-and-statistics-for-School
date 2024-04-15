-- task 1
CREATE OR REPLACE PROCEDURE insert_into_ptp(
       CheckedPeer varchar,
       PeerChecking varchar,
       ReviewedTask varchar,
       Status check_status,
       ReviewTime timestamp DEFAULT current_timestamp)
LANGUAGE plpgsql
AS $$
DECLARE
    check_id bigint;
BEGIN
    IF Status = 'start' THEN
       INSERT INTO checks VALUES (
       (SELECT MAX(id) + 1 AS id
       FROM checks),
       CheckedPeer,
       ReviewedTask,
       ReviewTime::date
       )
       RETURNING id INTO check_id;
    ELSE
        SELECT p2p.check_ INTO check_id
        FROM p2p
        JOIN checks ch ON p2p.check_ = ch.id
        WHERE p2p.checkingpeer = PeerChecking
          AND ch.peer = CheckedPeer
          AND ch.task = ReviewedTask
        ORDER BY 1 DESC
        LIMIT 1;
    END IF;
    INSERT INTO p2p VALUES (
                            (SELECT MAX(id) + 1 FROM p2p),
                            check_id,
                            PeerChecking,
                            Status,
                            ReviewTime::time
                           );
END;
$$;

-- test of task 1

-- failure ptp
CALL insert_into_ptp('wellpetr',
                     'steinbrp',
                     'CPP3_SmartCalc',
                     'start');

CALL insert_into_ptp('wellpetr',
                     'steinbrp',
                     'CPP3_SmartCalc',
                     'failure');

--success ptp
CALL insert_into_ptp('steinbrp',
                     'wellpetr',
                     'CPP3_SmartCalc',
                     'start');

CALL insert_into_ptp('steinbrp',
                     'wellpetr',
                     'CPP3_SmartCalc',
                     'success');

--truncate table checks, p2p;


-- task 2
CREATE OR REPLACE PROCEDURE insert_into_verter(
    CheckedPeer varchar,
    ReviewedTask varchar,
    VerterStatus check_status,
    ReviewTime timestamp DEFAULT current_timestamp
)
LANGUAGE plpgsql
AS $$
DECLARE
   check_id bigint := (SELECT checks.id
                       FROM checks
                           JOIN p2p
                               ON checks.id = p2p.check_
                       WHERE p2p.state = 'success'
                         AND checks.peer = CheckedPeer
                         AND checks.task = ReviewedTask
                       ORDER BY p2p.time DESC
                       LIMIT 1
    );
BEGIN
    IF (check_id IS NOT NULL) THEN
        INSERT INTO verter VALUES (
                                   (SELECT MAX(id) + 1 from verter),
                                   check_id,
                                   VerterStatus,
                                  ReviewTime::time
        );
    END IF;
END;
$$;

-- test of task 2
CALL insert_into_verter('steinbrp',
                        'CPP3_SmartCalc',
                        'start');

CALL insert_into_verter('steinbrp',
                        'CPP3_SmartCalc',
                        'success');
-- non-existent peer
CALL insert_into_verter('romakek',
                        'C1_SimpleBashUtils',
                        'start');
-- non-existent project
CALL insert_into_verter('steinbrp',
                        'C2_String',
                        'start');

-- failure p2p
CALL insert_into_verter('wellpetr',
                        'CPP3_SmartCalc',
                        'start');


-- task 3
CREATE OR REPLACE FUNCTION fnc_trg_p2p_insert_transfer_points() RETURNS TRIGGER AS
$trg_p2p_insert_transfer_points$
DECLARE
    checkedPerson varchar := (SELECT checks.peer
                            FROM checks
                            WHERE checks.id = NEW.check_);
    tp_id bigint := (SELECT tp.id
                    FROM transferredpoints tp
                    WHERE tp.checkedpeer = checkedPerson
                    AND tp.checkingpeer = NEW.CheckingPeer);
BEGIN
    IF (TG_OP = 'INSERT' AND NEW.state = 'start') THEN
        IF tp_id IS NOT NULL THEN
            UPDATE transferredpoints
            SET PointsAmount = PointsAmount + 1
            WHERE id = tp_id;
        ElSE
            INSERT INTO transferredpoints
            VALUES ((SELECT max(id) + 1
                            FROM transferredpoints),
                    NEW.CheckingPeer,
                    checkedPerson,
                    1);
        END if;
    END IF;
    RETURN NULL;
END;
$trg_p2p_insert_transfer_points$ LANGUAGE plpgsql;

CREATE TRIGGER trg_p2p_insert_transfer_points
    AFTER INSERT
    ON p2p
    FOR EACH ROW
EXECUTE FUNCTION fnc_trg_p2p_insert_transfer_points();

-- test for task 3

CALL insert_into_ptp('wellpetr',
                     'aboba',
                     'CPP3_SmartCalc',
                     'start');

CALL insert_into_ptp('wellpetr',
                     'aboba',
                     'CPP3_SmartCalc',
                     'failure');



-- task 4
CREATE OR REPLACE FUNCTION fnc_trg_xp_insert_validate() RETURNS TRIGGER AS
$trg_xp_insert_validate$
DECLARE
    check_id bigint := (SELECT checks.id
                        FROM checks
                        JOIN p2p ON checks.id = p2p.check_
                        WHERE checks.id = NEW.check_
                        AND p2p.state = 'success'
                            AND (checks.id NOT IN (SELECT check_ FROM verter)
                                    OR (SELECT check_
                                        FROM verter
                                            WHERE verter.check_ = checks.id
                                                AND verter.state = 'success') is NOT NULL));
BEGIN
    IF check_id IS NOT NULL
           AND (NEW.XPAmount <= (SELECT tasks.MaxXP
                                 FROM tasks
                                     JOIN checks ON checks.task = tasks.title
                                 WHERE checks.id = NEW.check_)) THEN
        RETURN (NEW.id, NEW.check_, NEW.XPAmount);
    ELSE
        RAISE EXCEPTION 'wrong xp';
    END if;
END;
$trg_xp_insert_validate$ LANGUAGE plpgsql;

CREATE TRIGGER trg_xp_insert_validate
    BEFORE INSERT
    ON xp
    FOR EACH ROW
EXECUTE FUNCTION fnc_trg_xp_insert_validate();

-- test for task 4

-- too much xp
INSERT INTO XP VALUES ((SELECT MAX(id) + 1 FROM XP), 20, 800);
-- failure p2p
INSERT INTO XP VALUES ((SELECT MAX(id) + 1 FROM XP), 22, 600);
--success p2p
INSERT INTO XP VALUES ((SELECT MAX(id) + 1 FROM XP), 20, 600);
