
create table opc_historic_values (
       timestamp timestamp,
       values text
);

create index opc_historic_values_timestamp_idx on opc_historic_values(timestamp);
