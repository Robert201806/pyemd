# distutils: language = c++

from libcpp.vector cimport vector
import cython

# Import both NumPy and the Cython declarations for NumPy
import numpy as np
cimport numpy as np


# Declare the interface to the C++ EMD library
# ============================================


cdef extern from "lib/emd_hat.hpp":
    cdef int emd_hat_gd_metric_int(vector[int],
                                   vector[int],
                                   vector[vector[int]]) except +

    cdef double emd_hat_gd_metric_double(vector[double],
                                         vector[double],
                                         vector[vector[double]]) except +

    cdef long int emd_hat_gd_metric_long_int(vector[long],
                                             vector[long],
                                             vector[vector[long]]) except +

    cdef long long int emd_hat_gd_metric_long_long_int(
        vector[long],
        vector[long],
        vector[vector[long]]) except +

    cdef int emd_hat_int(vector[int],
                         vector[int],
                         vector[vector[int]]) except +

    cdef double emd_hat_double(vector[double],
                               vector[double],
                               vector[vector[double]]) except +

    cdef long int emd_hat_long_int(vector[long],
                                   vector[long],
                                   vector[vector[long]]) except +

    cdef long long int emd_hat_long_long_int(vector[long],
                                             vector[long],
                                             vector[vector[long]]) except +


# NumPy array to C++ vector conversion
# ====================================


# See http://stackoverflow.com/a/2434208/1085344
cdef vector[double] _c_array_to_vector(double* array, int length):
    cdef vector[double] output_vector
    output_vector.reserve(length)
    output_vector.assign(array, array + length)
    return output_vector


# See https://github.com/cython/cython/wiki/tutorials-NumpyPointerToC
@cython.boundscheck(False)
@cython.wraparound(False)
def _np_array_to_vector(np.ndarray[double, ndim=1, mode="c"] array):
    """Convert a 1D numpy array to a C++ vector.

    :param array: A 1D numpy array of ``np.double``.

    """
    cdef vector[double] output_vector
    cdef int length
    length = array.size

    # Pass pointer to beginning of numpy array data
    output_vector = _c_array_to_vector(&array[0], length)

    return output_vector


def _2d_np_array_to_2d_vector(np.ndarray[double, ndim=2, mode="c"] matrix):
    """Convert a 2D numpy array to a C++ vector of vectors.

    :param array: A 2D numpy array of ``np.double``.

    """
    cdef vector[vector[double]] output_matrix
    cdef vector[double] c_row

    for row in matrix:
        c_row = _np_array_to_vector(row)
        output_matrix.push_back(c_row)

    return output_matrix


# Define the API
# ==============


def emd(np.ndarray[double, ndim=1, mode="c"] first_signature,
        np.ndarray[double, ndim=1, mode="c"] second_signature,
        np.ndarray[double, ndim=2, mode="c"] distance_matrix):
    """Compute the Earth Mover's Distance between the given signatures with the
    given distance matrix.

    :param first_signature: A 1D numpy array of ``np.double``.
    :param second_signature: A 1D numpy array of ``np.double``.
    :param distance_matrix: A 2D numpy array of ``np.double``.

    """
    # Convert numpy input to C++ vectors
    cdef vector[double] c_first_signature
    cdef vector[double] c_second_signature
    cdef vector[vector[double]] c_distance_matrix
    c_first_signature = _np_array_to_vector(first_signature)
    c_second_signature = _np_array_to_vector(second_signature)
    c_distance_matrix = _2d_np_array_to_2d_vector(distance_matrix)

    return emd_hat_gd_metric_double(c_first_signature,
                                    c_second_signature,
                                    c_distance_matrix)
