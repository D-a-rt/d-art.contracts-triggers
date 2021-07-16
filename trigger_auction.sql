create extension dblink;

--  Trigger and Function that update the price of the preconfigured auction if any changes happen

CREATE OR REPLACE FUNCTION preconfigured_auctions()
RETURNS trigger AS $$

BEGIN
    PERFORM dblink_connect('host=d-art-db dbname=postgres user=postgres password=p@ssw0rd port=5432'); 

    IF (TG_OP = 'INSERT' AND NOT NEW.deleted) THEN        

        PERFORM dblink_exec('
            UPDATE auction SET starting_price = ' || NEW.opening_price/1000000 || 
            ' WHERE token_info ->> ''tokenId'' = ' || quote_literal(NEW.idx_token_id) || 
            ' AND token_info ->> ''contractAddress'' = ' || quote_literal(NEW.idx_token_address) || 
            ' AND end_date IS NULL;');

    END IF;
    
    PERFORM dblink_disconnect();
    
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER preconfigured_auction_insertion_trigger
AFTER INSERT
ON "storage.preconfigured_auctions"
FOR EACH ROW EXECUTE PROCEDURE preconfigured_auctions();


--  Trigger and Function that update the auction end_date and the bids table of the d-art.backend when user bids on 

CREATE OR REPLACE FUNCTION auctions()
RETURNS trigger AS $$

BEGIN
    PERFORM dblink_connect('host=d-art-db dbname=postgres user=postgres password=p@ssw0rd port=5432'); 

    IF (TG_OP = 'INSERT') THEN

        PERFORM dblink_exec('
            UPDATE auction SET end_date = ' || quote_literal(NEW.end_time) || 
            ' WHERE token_info ->> ''tokenId'' = ' || quote_literal(NEW.idx_token_id) || 
            ' AND token_info ->> ''contractAddress'' = ' || quote_literal(NEW.idx_token_address) || 
            ' AND (end_date > NOW() OR end_date IS NULL);'
        );

        PERFORM dblink_exec('
            INSERT INTO bid (
                bid_price, 
                created_at, 
                concerned_auction, 
                user_address
            )
            VALUES (
                ' || NEW.current_bid/1000000 || ', 
                ' || quote_literal(NEW.last_bid_time) || ', 
                  (SELECT auction_id FROM auction 
                  WHERE token_info ->> ''tokenId'' = ' || quote_literal(NEW.idx_token_id) || 
                ' AND token_info ->> ''contractAddress'' = ' || quote_literal(NEW.idx_token_address) || 
                ' AND end_date > NOW() ), 
                ' || quote_literal(NEW.highest_bidder) || ');'
        );
        
        IF (NEW.deleted) THEN
            PERFORM dblink_exec('
                UPDATE auction SET claimed = ' || true || 
                ' WHERE token_info ->> ''tokenId'' = ' || quote_literal(NEW.idx_token_id) || 
                ' AND token_info ->> ''contractAddress'' = ' || quote_literal(NEW.idx_token_address) || 
                ' AND end_date = (
                    SELECT MAX(end_date) FROM auction 
                    WHERE token_info ->> ''tokenId'' = ' || quote_literal(NEW.idx_token_id) || 
                    ' AND token_info ->> ''contractAddress'' = ' || quote_literal(NEW.idx_token_address) || ' )'
            );
        END IF;        
    END IF;

    PERFORM dblink_disconnect();
    RETURN NULL;
END;

$$ LANGUAGE plpgsql;


CREATE TRIGGER auction_insertion_trigger
AFTER INSERT
ON "storage.auctions"
FOR EACH ROW EXECUTE PROCEDURE auctions();


