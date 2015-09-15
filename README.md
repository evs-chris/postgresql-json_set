# json_set for PostgreSQL

Updating JSON fields in PostgreSQL tables is challenging. It looks like 9.5 will have more helpers, but the set helper is only for JSONB.

This is an extension of [this](http://stackoverflow.com/a/23500670) StackOverflow answer. It combines the top-level-only set with the path set, adds support for setting values in nested arrays, makes upsert optional, and provides a more convenient javascripty setter for paths.

There are two variants:

* `json_set(json, path_array, value[, upsert = true])` - the path array should be a varchar[] or something close to it.
```sql
-- updating a value
select json_set('{"outer":{"inner":{"foo":"bar"}, "arr":[1,2,false]}}', ARRAY['outer','inner','foo'], 10);
-- {"outer":{"arr":[1,2,false],"inner":{"foo":10}}}

-- set without upsert is a noop
select json_set('{"outer":{"inner":{"foo":"bar"}, "arr":[1,2,false]}}', ARRAY['missing'], 10, false);
-- {"outer":{"inner":{"foo":"bar"}, "arr":[1,2,false]}}

-- set missing for upsert
select json_set('{"outer":{"inner":{"foo":"bar"}, "arr":[1,2,false]}}', ARRAY['missing'], 10, true);
-- {"outer":{"inner":{"foo":"bar"}, "arr":[1,2,false]},"missing":10}

-- set inside an array
select json_set('{"outer":{"inner":{"foo":"bar"}, "arr":[1,2,false]}}', ARRAY['outer', 'arr', '0'], true);
-- {"outer":{"inner":{"foo":"bar"},"arr":[true, 2, false]}}
```

* `json_set(json, path_string, value[, upsert = true])` - the path string should be a `.` separated keypath.
```sql
-- updating a value
select json_set('{"outer":{"inner":{"foo":"bar"}, "arr":[1,2,false]}}', 'outer.inner.foo', 10);
-- {"outer":{"arr":[1,2,false],"inner":{"foo":10}}}

-- set without upsert is a noop
select json_set('{"outer":{"inner":{"foo":"bar"}, "arr":[1,2,false]}}', 'missing', 10, false);
-- {"outer":{"inner":{"foo":"bar"}, "arr":[1,2,false]}}

-- set missing for upsert
select json_set('{"outer":{"inner":{"foo":"bar"}, "arr":[1,2,false]}}', 'missing', 10, true);
-- {"outer":{"inner":{"foo":"bar"}, "arr":[1,2,false]},"missing":10}

-- set inside an array
select json_set('{"outer":{"inner":{"foo":"bar"}, "arr":[1,2,false]}}', 'outer.arr.0', true);
-- {"outer":{"inner":{"foo":"bar"},"arr":[true, 2, false]}}
```

## In practice

```
UPDATE foos SET some_json_field = json_set(some_json_field, 'my.path', 123) WHERE some_other_field = 'condition';
```
