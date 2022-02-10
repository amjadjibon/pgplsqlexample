------------------------------------------------------------------------------------------------------------------------
DO
$BODY$
    DECLARE

    BEGIN

    END
$BODY$ LANGUAGE plpgsql;
------------------------------------------------------------------------------------------------------------------------

--- In PostgreSQL, you use single quotes for a string constant like this:
select 'String constant';

-- When a string constant contains a single quote ('),
-- you need to escape it by doubling up the single quote. For example:
select 'I''m also a string constant';

-- If you use an old version of PostgreSQL,
-- you can prepend the string constant with E to declare the postfix escape string syntax
-- and use the backslash \ to escape the single quote like this:
select E'I\'m also a string constant';

-- The following shows the syntax of the dollar-quoted string constants:
select $$I'm a string constant that contains a backslash \$$;

-- In this example, we used the string message as a tag between the two dollar signs ($ )
SELECT $message$I'm a string constant that contains a backslash \$message$;

-- Using dollar-quoted string constant in anonymous blocks
do
'declare
    wallet_count integer;
begin
select count(*) into wallet_count
from fiio_wallet;
raise notice ''The number of wallet: %'', wallet_count;
end;';

-- The code in the block must be surrounded by single quotes.
-- If it has any single quote, you need to escape it by doubling it like this:
--  raise notice ''The number of films: %'', film_count;

-- To avoid escaping every single quotes and backslashes,
-- you can use the dollar-quoted string as follows:
do
$$
    declare
        wallet_count integer;
    begin
        select count(*)
        into wallet_count
        from fiio_wallet;
        raise notice 'The number of wallet: %', wallet_count;
    end;
$$;
-- In this example, you don’t need to escape the single quotes and backslashes.

-- Using dollar-quoted string constants in functions
-- The following shows the syntax of the CREATE FUNCTION statement that allows you to create a user-defined function
-- create function function_name(param_list)
--     returns datatype
-- language lang_name
-- as
--  'function_body'

create function find_wallet_by_id(
    wallet_id int
) returns fiio_wallet
    language sql
as
'select *
 from fiio_wallet
 where id = wallet_id';
-- As you can see, the body of the find_film_by_id() function is surrounded by single quotes.
-- If the function has many statements, it becomes more difficult to read.
-- In this case, you can use dollar-quoted string constant syntax:
create function find_wallet_by_id_new(
    wallet_id int
) returns fiio_wallet
    language sql
as
$$
select *
from fiio_wallet
where id = wallet_id;
$$;

-- Using dollar-quoted string constants in stored procedures
-- Similarly, you can use the dollar-quoted string constant syntax in stored procedures like this:
-- create procedure proc_name(param_list)
-- language lang_name
-- as $$
--   -- stored procedure body
-- $$

do
$$
    <<first_block>>
        declare
        wallet_id integer := 0;
    begin
        -- get the number of films
        select count(*)
        into wallet_id
        from fiio_wallet;
        -- display a message
        raise notice 'The number of wallet is %', wallet_id;
    end first_block
$$;

--- variables
do
$$
    declare
        counter    integer        := 1;
        first_name varchar(50)    := 'John';
        last_name  varchar(50)    := 'Doe';
        payment    numeric(10, 2) := 25.69;
    begin
        raise notice '%. % % has been paid % USD',
            counter,
            first_name,
            last_name,
            payment;
    end
$$;

do
$$
    DECLARE
        created_at time := now();
        updated_at time;
    begin
        raise notice 'Time: %', created_at;
        perform pg_sleep(5);
        updated_at = now();
        raise notice 'Time: %', updated_at;
    end
$$;

do
$$
    DECLARE
        wallet_id      fiio_wallet.id%type;
        wallet_number  fiio_wallet.number%type;
        wallet_balance fiio_wallet.balance%type;
    BEGIN
        wallet_id := 100007;
        wallet_balance := (SELECT balance FROM fiio_wallet WHERE id = wallet_id);
        wallet_number := (SELECT number FROM fiio_wallet WHERE id = wallet_id);
        RAISE NOTICE 'Wallet ID: %, Number: %, Balance: %', wallet_id, wallet_number, wallet_balance;
    END
$$;

do
$$
    DECLARE
        wallet_count INTEGER;
    BEGIN
        SELECT count(*) INTO wallet_count FROM fiio_wallet;
        RAISE NOTICE 'The number of wallet: %', wallet_count;
    END
$$;

-- Row type variables
DO
$$
    DECLARE
        selected_wallet fiio_wallet%rowtype;
    BEGIN
        SELECT * INTO selected_wallet FROM fiio_wallet WHERE id = 100007;

        RAISE NOTICE 'Wallet ID: %, Wallet Number: %, Balance: %, Persona: %',
            selected_wallet.id, selected_wallet.number, selected_wallet.balance, selected_wallet.persona;
    END;
$$ LANGUAGE plpgsql;

DO
$BODY$
    DECLARE
        wallet fiio_wallet;
    BEGIN
        SELECT *
        INTO wallet
        FROM fiio_wallet
        WHERE id = 100007;

        -- RAISE WALLET INFORMATION
        RAISE NOTICE '% % % %', wallet.id, wallet.number, wallet.persona, wallet.balance;
    END;
$BODY$
LANGUAGE plpgsql;

-- LOOP
DO
$BODY$
    DECLARE
        wallet fiio_wallet;
    BEGIN
        FOR wallet IN SELECT * FROM fiio_wallet WHERE persona = 5 ORDER BY id
            LOOP
                RAISE NOTICE '% % % %', wallet.id, wallet.number, wallet.persona, wallet.balance;
            END LOOP;
    END;
$BODY$;

DO
$BODY$
    DECLARE
        device fiio_device_authorized;
    BEGIN
        FOR device IN SELECT * FROM fiio_device_authorized WHERE wallet_id BETWEEN 100001 AND 100009 ORDER BY wallet_id
            LOOP
                RAISE NOTICE '% %', device.wallet_id, device.uuid;
            END LOOP;
    END
$BODY$ LANGUAGE plpgsql;

-- CONSTANT
DO
$BODY$
    DECLARE
        vat CONSTANT numeric := 0.1;
        net_price    numeric := 20.5;
    BEGIN
        RAISE NOTICE 'The selling price is %', net_price * (1 + vat);
    END
$BODY$ LANGUAGE plpgsql;

DO
$BODY$
    DECLARE
        created_at constant time := now();
    BEGIN
        RAISE NOTICE 'Start executing block at %', created_at;
    END;
$BODY$ LANGUAGE plpgsql;

-- logger
DO
$BODY$
    BEGIN
        RAISE INFO 'Information message %', now();
        RAISE LOG 'Log message %', now();
        RAISE DEBUG 'Debug message %', now();
        RAISE WARNING 'Warning message %', now();
        RAISE NOTICE 'Notice message %', now();
    END
$BODY$ LANGUAGE plpgsql;

-- assert
DO
$BODY$
    DECLARE
        wallet_count integer;
    BEGIN
        select count(*)
        into wallet_count
        from fiio_wallet;

        assert wallet_count > 100, 'Wallet found more than 100';
    END
$BODY$ LANGUAGE plpgsql;

-- if statement

DO
$BODY$
    DECLARE
        selected_wallet fiio_wallet%rowtype;
        input_wallet_id fiio_wallet.id%type := 100007;
    BEGIN
        SELECT * INTO selected_wallet FROM fiio_wallet WHERE id = input_wallet_id;
        IF NOT FOUND THEN
            RAISE NOTICE 'The wallet % not found in database', input_wallet_id;
        ELSE
            RAISE NOTICE 'The wallet % found in database. Number: %', input_wallet_id, selected_wallet.number;
        END IF;
    END
$BODY$ LANGUAGE plpgsql;

-- case

DO
$BODY$
    DECLARE
        persona_data    fiio_wallet.persona%type;
        input_wallet_id integer := 100005;
        persona_str     varchar(20);
    BEGIN
        select persona into persona_data from fiio_wallet where id = input_wallet_id;

        if FOUND then
            case persona_data
                when 7 then persona_str := 'customer';
                when 6 then persona_str := 'merchant';
                when 5 then persona_str := 'agent';
                when 4 then persona_str := 'dso';
                when 3 then persona_str := 'distributor';
                else persona_str := 'unspecified';
                end case;
        end if;

        raise notice 'Wallet ID: %, Persona: %', input_wallet_id, persona_str;
    END
$BODY$ LANGUAGE plpgsql;

-- case
DO
$BODY$
    DECLARE
        total_balance         numeric;
        total_blocked_balance numeric;
        total_frozen_balance  numeric;
    BEGIN
        select sum(balance), sum(blocked_balance), sum(frozen_balance)
        into total_balance, total_blocked_balance, total_frozen_balance
        from fiio_wallet
        where id between 100001 and 100009;

        raise notice 'Total balance: %', total_balance;
        raise notice 'Total blocked balance: %', total_blocked_balance;
        raise notice 'Total frozen balance: %', total_frozen_balance;
    END
$BODY$ LANGUAGE plpgsql;

-- loop statement
DO
$BODY$
    DECLARE
        n       integer := 5;
        fib     integer := 0;
        counter integer := 0;
        i       integer := 0;
        j       integer := 1;
    BEGIN
        if (n < 1) then
            fib := 0;
        end if;

        loop
            exit when counter = n;
            counter := counter + 1;

            -- The following select statement swaps values of two variables
            select j, i + j into i, j;
        end loop;
        fib := i;
        raise notice '%', fib;
    END
$BODY$ LANGUAGE plpgsql;

-- while loop
DO
$BODY$
    DECLARE
        counter integer := 0;
    BEGIN
        while counter < 10
            loop
                raise notice 'Counter: %', counter;
                counter := counter + 1;
            end loop;

    END
$BODY$ LANGUAGE plpgsql;

-- for loop
DO
$BODY$
    BEGIN
        for counter in 1..10
            loop
                raise notice 'counter: %', counter;
            end loop;
    END
$BODY$ LANGUAGE plpgsql;

-- for loop reverse
DO
$BODY$
    BEGIN
        for counter in reverse 10..1
            loop
                raise notice 'counter: %', counter;
            end loop;
    END
$BODY$ LANGUAGE plpgsql;

-- adds two to counter after each iteration
DO
$BODY$
    BEGIN
        for counter in 1..10 by 2
            loop
                raise notice 'counter: %', counter;
            end loop;
    END
$BODY$ LANGUAGE plpgsql;

DO
$BODY$
    DECLARE
        wallet fiio_wallet;
    BEGIN
        for wallet in select * from fiio_wallet where id between 100001 and 100009 order by id limit 10
            loop
                raise notice 'Wallet Number: %, Balance: %', wallet.number, wallet.balance + wallet.frozen_balance + wallet.frozen_balance;
            end loop;
    END
$BODY$ LANGUAGE plpgsql;

-- build a dynamic query
DO
$BODY$
    DECLARE
        sort_type    smallint := 1;
        wallet_count int      := 5;
        wallet       fiio_wallet;
        query        text;
    BEGIN
        query := 'select * from fiio_wallet where id between 100001 and 100009 ';
        if sort_type = 1 then
            query := query || 'order by id';
        elseif sort_type = 2 then
            query := query || 'order by balance desc';
        else
            raise notice 'Invalid sort type: %',sort_type;
        end if;

        query := query || ' limit $1';

        for wallet in execute query using wallet_count
            loop
                raise notice 'ID: %, Balance: %', wallet.id, wallet.balance;
            end loop;
    END
$BODY$ LANGUAGE plpgsql;

--  Exit statement to terminate an unconditional loop
DO
$BODY$
    DECLARE
        i int = 0;
        j int = 0;
    BEGIN
        <<outer_loop>>
        loop
            i = i + 1;
            exit when i > 3;
            j = 0;
            <<inner_loop>>
            loop
                j = j + 1;
                exit when j > 3;
                raise notice '(i,j): (%,%)', i, j;
            end loop inner_loop;
        end loop outer_loop;
    END
$BODY$ LANGUAGE plpgsql;

DO
$BODY$
    DECLARE
        i int = 0;
        j int = 0;
    BEGIN
        <<outer_loop>>
        loop
            i = i + 1;
            exit when i > 3;
            j = 0;
            <<inner_loop>>
            loop
                j = j + 1;
                exit outer_loop when j > 3;
                raise notice '(i,j): (%,%)', i, j;
            end loop inner_loop;
        end loop outer_loop;
    END
$BODY$ LANGUAGE plpgsql;

DO
$BODY$
    BEGIN
        <<simple_block>>
        BEGIN
            exit simple_block;
            -- for demo purpose below code will not execute
            raise notice 'Unreachable';
        END;
        raise notice 'End of block';
    END
$BODY$ LANGUAGE plpgsql;

-- Continue statement example

DO
$BODY$
    DECLARE
        counter int = 0;
    BEGIN
        loop
            counter = counter + 1;
            exit when counter > 10;
            -- skip even numbers
            continue when mod(counter, 2) = 0;
            raise notice '%', counter;
        end loop;
    END
$BODY$ LANGUAGE plpgsql;

DO
$BODY$
    DECLARE
        counter int = 0;
    BEGIN
        loop
            counter = counter + 1;
            exit when counter > 10;
            -- skip odd numbers
            continue when mod(counter, 2) != 0;
            raise notice '%', counter;
        end loop;
    END
$BODY$ LANGUAGE plpgsql;
