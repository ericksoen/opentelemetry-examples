############################
## Sampling Rules Config ##
############################

# DryRun - If enabled, marks traces that would be dropped given current sampling rules,
# and sends all traces regardless
DryRun = false

# DryRunFieldName - the key to add to use to add to event data when using DryRun mode above, defaults to refinery_kept
# DryRunFieldName = "refinery_kept"

# DeterministicSampler is a section of the config for manipulating the
# Deterministic Sampler implementation. This is the simplest sampling algorithm
# - it is a static sample rate, choosing traces randomly to either keep or send
# (at the appropriate rate). It is not influenced by the contents of the trace.
Sampler = "DeterministicSampler"

# SampleRate is the rate at which to sample. It indicates a ratio, where one
# sample trace is kept for every n traces seen. For example, a SampleRate of 30
# will keep 1 out of every 30 traces. The choice on whether to keep any specific
# trace is random, so the rate is approximate.
# Eligible for live reload.
SampleRate = 25

[${HONEYCOMB_DATASET_NAME}]

    Sampler = "RulesBasedSampler"

    [[${HONEYCOMB_DATASET_NAME}.rule]]
        name = "Return all 401 errors"
        SampleRate = 1
        [[${HONEYCOMB_DATASET_NAME}.rule.condition]]
            field = "http.status_code"
            operator = "="
            value = 401
    [[${HONEYCOMB_DATASET_NAME}.rule]]
        name = "Return all 5xx errors"
        SampleRate = 1
        [[${HONEYCOMB_DATASET_NAME}.rule.condition]]
            field = "http.status_code"
            operator = ">="
            value = 500
    [[${HONEYCOMB_DATASET_NAME}.rule]]
        name = "Return all slow requests"
        SampleRate = 1
        [[${HONEYCOMB_DATASET_NAME}.rule.condition]]
            field = "duration_ms"
            operator = ">="
            value = 2000
    [[${HONEYCOMB_DATASET_NAME}.rule]]
        name = "heavily sample health checks"
        SampleRate = 100
        [[${HONEYCOMB_DATASET_NAME}.rule.condition]]
            field = "http.target"
            operator = "="
            value = "/status"

    [[${HONEYCOMB_DATASET_NAME}.rule]]
        SampleRate = 2

        