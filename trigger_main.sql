-- Create Trigger when a bid is placed 

CREATE OR REPLACE FUNCTION bid_notification()
            RETURNS trigger AS $$
            DECLARE
                current_row RECORD;
                join_query_result RECORD;
            BEGIN
                IF (TG_OP = 'INSERT') THEN
                    current_row := NEW;
                ELSE
                    current_row := OLD;
                END IF;
                IF (TG_OP = 'INSERT') THEN
                    OLD := NEW;
                END IF;
            
                SELECT bid.id, bid.created_at, bid.concerned_auction, bid.bid_price, users.profile_picture, users.name
                INTO join_query_result
                FROM bid, users 
                WHERE current_row.user_address = users.address;
                
                PERFORM pg_notify(
                    'bid_insertion_notification',
                    json_build_object(
                        'bid_insertion_notification',
                        json_build_object(
                            'id', join_query_result.id,
                            'createdAt', join_query_result.created_at,
                            'concernedAuction', json_build_object(
                                'auctionId', current_row.concerned_auction
                                )::jsonb,
                            'bider', json_build_object(
                                'profilePicture', join_query_result.profile_picture,
                                'address', current_row.user_address,
                                'name', join_query_result.name
                                )::jsonb,
                            'bidPrice', current_row.bid_price
                        )::jsonb
                    )::text
                );
                
                RETURN current_row;
            END;
            $$ LANGUAGE plpgsql;
            
             CREATE TRIGGER bid_insertion_trigger
            AFTER INSERT
            ON bid
            FOR EACH ROW EXECUTE PROCEDURE bid_notification();


-- Auction trigger

CREATE OR REPLACE FUNCTION auction_notification()
RETURNS trigger AS $$
	DECLARE
	    current_row RECORD;
	BEGIN
	
	    IF (TG_OP = 'INSERT') THEN
	        current_row := NEW;
	    ELSE
	        current_row := OLD;
	    END IF;
	    IF (TG_OP = 'INSERT') THEN
	        OLD := NEW;
	    END IF;
	
	    PERFORM pg_notify(
	        'auction_insertion_notification',
	        json_build_object(
	            'auction_insertion_notification',
	            json_build_object(
	                'auctionId', current_row.auction_id,
	                'startingPrice', current_row.starting_price,
	                'contractAddress', current_row.auction_id,
	                'endDate', current_row.end_date
	            )::jsonb
	        )::text
	    );
	
	    RETURN current_row;
	END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER auction_insertion_trigger
            AFTER INSERT
            ON auction
            FOR EACH ROW EXECUTE PROCEDURE auction_notification();

