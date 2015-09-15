CREATE OR REPLACE FUNCTION "json_set"(
  "json"          json,
  "key_path"      TEXT[],
  "value_to_set"  anyelement,
  "create_missing" boolean default true
)
  RETURNS json
  LANGUAGE sql
  IMMUTABLE
  STRICT
AS $function$
SELECT CASE COALESCE(array_length("key_path", 1), 0)
      WHEN 0 THEN to_json("value_to_set")
      WHEN 1 THEN
        (SELECT CASE WHEN ("json" -> "key_path"[1]) IS NULL AND "create_missing" = false
        THEN "json"
        ELSE
          (SELECT CASE WHEN json_typeof("json") = 'array'
            THEN (SELECT concat(
              '[',
              array_to_string(
                ((select ((array_agg(a))[0:("key_path"[1]::integer)])::varchar[] from json_array_elements("json") a)::varchar[] ||
                to_json("value_to_set")::varchar) ||
                (select ((array_agg(a))[("key_path"[1]::integer + 2):(array_length(array_agg(a), 1))])::varchar[] from json_array_elements("json") a)::varchar[]
              , ', '),
              ']'
            )::json)
            ELSE (SELECT concat('{', string_agg(to_json("key") || ':' || "value", ','), '}')::json
              FROM (SELECT *
                FROM json_each("json")
                  WHERE "key" <> "key_path"[1]
            UNION ALL
            SELECT "key_path"[1], to_json("value_to_set")) AS "fields")
          END)
        END)
      ELSE "json_set"(
        "json",
        ARRAY["key_path"[l]],
        "json_set"(
          COALESCE(NULLIF(("json" -> "key_path"[l])::text, 'null'), '{}')::json,
          "key_path"[l+1:u],
          "value_to_set",
          "create_missing"
        ),
        "create_missing"
      )
    END
  FROM array_lower("key_path", 1) l,
       array_upper("key_path", 1) u
$function$;

CREATE OR REPLACE FUNCTION json_set(
  "json"          json,
  "key_path"      varchar,
  "value_to_set"  anyelement,
  "create_missing" boolean default true
)
  RETURNS json
  LANGUAGE sql
  IMMUTABLE
  STRICT
AS $function$
  SELECT json_set("json", string_to_array("key_path", '.'), "value_to_set", "create_missing");
$function$;
