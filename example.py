import ctypes
import sys
import inspect
import atexit
import numpy


import gc

def should_have_no_effect():
    h(3)

def g():
    h(1)
    h(2)
    h(1)

def return_some_data_that_isnt_freed():
    return numpy.ones((1024, 1024, 2), dtype=numpy.uint8)

def h(i):
    s = numpy.ones((1024, 1024, i), dtype=numpy.uint8)
    del s

def demo():
    print("DEMO TIME!")
    g()
    should_have_no_effect()
    x = return_some_data_that_isnt_freed()
    h(5)

if __name__ == '__main__':
    demo()