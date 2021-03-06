create extension dblink;

--  Trigger and Function that update the owner of an nft (Here an artwork) after a transaction

CREATE OR REPLACE FUNCTION update_token_owner()
RETURNS TRIGGER AS $$

BEGIN
    PERFORM dblink_connect('host=<HOST> dbname=<DB_NAME> user=<USER> password=<PASSWORD> port=<PORT>'); 

    IF (TG_OP = 'INSERT') THEN
        PERFORM dblink_exec(
            
            'UPDATE artwork SET owner_id = user_subquery.id FROM (SELECT id FROM users WHERE address = '|| quote_literal(NEW.assets_address_5) ||') AS user_subquery
            WHERE token_info ->> ''tokenId'' = ' || quote_literal(NEW.idx_assets_nat_4) ||
            'AND token_info ->> ''contractAddress'' = ''KT1E...'' ;'
        );
    END IF;

    PERFORM dblink_disconnect();
    RETURN NULL;
END; 

$$ LANGUAGE plpgsql;

CREATE TRIGGER token_ownership_trigger
AFTER INSERT 
ON "storage.ledger"
FOR EACH ROW EXECUTE PROCEDURE update_token_owner();

CREATE OR REPLACE FUNCTION update_minter()
RETURNS TRIGGER AS $$

BEGIN
    PERFORM dblink_connect('host=<HOST> dbname=<DB_NAME> user=<USER> password=<PASSWORD> port=<PORT>'); 

    IF (TG_OP = 'INSERT' AND NOT NEW.deleted) THEN
        PERFORM dblink_exec(
            'UPDATE users SET role = ''creator''::users_role_enum ' 
            'WHERE address = ' || quote_literal(NEW.idx_assets_address_6) ||
            ' ;'
        );
    END IF;

    IF (TG_OP = 'INSERT' AND NEW.deleted) THEN
        PERFORM dblink_exec(
            'UPDATE users SET role = ''collector''::users_role_enum ' 
            'WHERE address = ' || quote_literal(NEW.idx_assets_address_6) ||
            ' ;'
        );
    END IF;

    PERFORM dblink_disconnect();
    RETURN NULL;
END;

$$ LANGUAGE plpgsql;

CREATE TRIGGER user_role_trigger
AFTER INSERT
ON "storage.minters"
FOR EACH ROW EXECUTE PROCEDURE update_minter()



