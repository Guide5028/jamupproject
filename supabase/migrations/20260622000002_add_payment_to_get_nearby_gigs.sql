-- Add payment + payment_unit to the nearby-gigs RPC so the app shows the real
-- price instead of "Negotiable". The Gig model reads json['payment'] /
-- json['payment_unit'], but the function wasn't returning them.
-- (Return type changed, so we DROP then CREATE rather than CREATE OR REPLACE.)
DROP FUNCTION IF EXISTS public.get_nearby_gigs(double precision, double precision, double precision);

CREATE FUNCTION public.get_nearby_gigs(user_lat double precision, user_lng double precision, radius_km double precision DEFAULT 50)
 RETURNS TABLE(id uuid, title text, description text, date timestamp without time zone, location text, latitude double precision, longitude double precision, venue_id uuid, image_url text, genres text[], payment numeric, payment_unit text, distance_km double precision)
 LANGUAGE sql
 STABLE
 SET search_path TO 'public', 'extensions'
AS $function$
  SELECT
    g.id, g.title, g.description, g.date,
    g.location, g.latitude, g.longitude,
    g.venue_id, g.image_url, g.genres,
    g.payment, g.payment_unit,
    (6371 * acos(
      cos(radians(user_lat)) * cos(radians(g.latitude)) *
      cos(radians(g.longitude) - radians(user_lng)) +
      sin(radians(user_lat)) * sin(radians(g.latitude))
    )) AS distance_km
  FROM gigs g
  WHERE
    g.latitude  IS NOT NULL AND g.longitude IS NOT NULL
    AND g.date >= NOW()
    AND g.latitude  BETWEEN user_lat - (radius_km / 111.0)
                        AND user_lat + (radius_km / 111.0)
    AND g.longitude BETWEEN user_lng - (radius_km / 111.0)
                        AND user_lng + (radius_km / 111.0)
    AND (6371 * acos(
      cos(radians(user_lat)) * cos(radians(g.latitude)) *
      cos(radians(g.longitude) - radians(user_lng)) +
      sin(radians(user_lat)) * sin(radians(g.latitude))
    )) <= radius_km
  ORDER BY distance_km ASC;
$function$;
