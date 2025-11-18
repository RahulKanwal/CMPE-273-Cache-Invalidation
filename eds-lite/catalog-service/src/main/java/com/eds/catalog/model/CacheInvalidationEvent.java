package com.eds.catalog.model;

import com.fasterxml.jackson.annotation.JsonCreator;
import com.fasterxml.jackson.annotation.JsonProperty;

import java.time.Instant;
import java.util.List;

public class CacheInvalidationEvent {
    private String ns;
    private List<String> keys;
    private Integer version;
    private Instant ts;
    private String cause;

    @JsonCreator
    public CacheInvalidationEvent(
            @JsonProperty("ns") String ns,
            @JsonProperty("keys") List<String> keys,
            @JsonProperty("version") Integer version,
            @JsonProperty("ts") Instant ts,
            @JsonProperty("cause") String cause) {
        this.ns = ns;
        this.keys = keys;
        this.version = version;
        this.ts = ts;
        this.cause = cause;
    }

    public String getNs() {
        return ns;
    }

    public void setNs(String ns) {
        this.ns = ns;
    }

    public List<String> getKeys() {
        return keys;
    }

    public void setKeys(List<String> keys) {
        this.keys = keys;
    }

    public Integer getVersion() {
        return version;
    }

    public void setVersion(Integer version) {
        this.version = version;
    }

    public Instant getTs() {
        return ts;
    }

    public void setTs(Instant ts) {
        this.ts = ts;
    }

    public String getCause() {
        return cause;
    }

    public void setCause(String cause) {
        this.cause = cause;
    }
}

