/* Copyright (C) 2005-2013 Shugo Maeda <shugo@ruby-lang.org> and Charlie Savage <cfis@savagexi.com>
   Please see the LICENSE file for copyright and distribution information */

/* :nodoc: */

#include "rp_measurement.h"

static VALUE cMeasureMemory;

static double
measure_memory_via_tracing(rb_trace_arg_t* trace_arg)
{
    static double result = 0;

    if (trace_arg)
    {
        rb_event_flag_t event = rb_tracearg_event_flag(trace_arg);
        if (event == RUBY_INTERNAL_EVENT_NEWOBJ)
        {
            VALUE object = rb_tracearg_object(trace_arg);
            result += rb_obj_memsize_of(object);
        }
    }
    return result;
}

prof_measurer_t* prof_measurer_memory(bool track_allocations)
{
  prof_measurer_t* measure = ALLOC(prof_measurer_t);
  measure->mode = MEASURE_MEMORY;
  measure->measure = measure_memory_via_tracing;
  measure->multiplier = 1;
  measure->track_allocations = true;
  return measure;
}

void rp_init_measure_memory()
{
    rb_define_const(mProf, "MEMORY", INT2NUM(MEASURE_MEMORY));

    cMeasureMemory = rb_define_class_under(mMeasure, "Allocations", rb_cObject);
}
