/* Generated automatically by H5detect -- do not edit */



/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 * Copyright by The HDF Group.                                               *
 * All rights reserved.                                                      *
 *                                                                           *
 * This file is part of HDF5.  The full HDF5 copyright notice, including     *
 * terms governing use, modification, and redistribution, is contained in    *
 * the COPYING file, which can be found at the root of the source code       *
 * distribution tree, or in https://www.hdfgroup.org/licenses.               *
 * If you do not have access to either file, you may request a copy from     *
 * help@hdfgroup.org.                                                        *
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 * Created:		Jan 24, 2023
 *			u0_a101@localhost
 *
 * Purpose:		This machine-generated source code contains
 *			information about the various integer and
 *			floating point numeric formats found on this
 *			architecture.  The parameters below should be
 *			checked carefully and errors reported to the
 *			HDF5 maintainer.
 *			
 *			Each of the numeric formats listed below are
 *			printed from most significant bit to least
 *			significant bit even though the actual bytes
 *			might be stored in a different order in
 *			memory.     The integers above each binary byte
 *			indicate the relative order of the bytes in
 *			memory; little-endian machines have
 *			decreasing numbers while big-endian machines
 *			have increasing numbers.
 *			
 *			The fields of the numbers are printed as
 *			letters with `S' for the mantissa sign bit,
 *			`M' for the mantissa magnitude, and `E' for
 *			the exponent.  The exponent has an associated
 *			bias which can be subtracted to find the
 *			true exponent.    The radix point is assumed
 *			to be before the first `M' bit.     Any bit
 *			of a floating-point value not falling into one
 *			of these categories is printed as a question
 *			mark.  Bits of integer types are printed as
 *			`I' for 2's complement and `U' for magnitude.
 *			
 *			If the most significant bit of the normalized
 *			mantissa (always a `1' except for `0.0') is
 *			not stored then an `implicit=yes' appears
 *			under the field description.  In this case,
 *			the radix point is still assumed to be
 *			before the first `M' but after the implicit
 *			bit.
 *
 * Modifications:
 *
 *	DO NOT MAKE MODIFICATIONS TO THIS FILE!
 *	It was generated by code in `H5detect.c'.
 *
 *-------------------------------------------------------------------------
 */

/****************/
/* Module Setup */
/****************/

#include "H5Tmodule.h"          /* This source code file is part of the H5T module */


/***********/
/* Headers */
/***********/
#include "H5private.h"        /* Generic Functions            */
#include "H5Eprivate.h"        /* Error handling              */
#include "H5FLprivate.h"    /* Free Lists                */
#include "H5Iprivate.h"        /* IDs                      */
#include "H5Tpkg.h"        /* Datatypes                 */


/****************/
/* Local Macros */
/****************/


/******************/
/* Local Typedefs */
/******************/


/********************/
/* Package Typedefs */
/********************/


/********************/
/* Local Prototypes */
/********************/


/********************/
/* Public Variables */
/********************/


/*****************************/
/* Library Private Variables */
/*****************************/


/*********************/
/* Package Variables */
/*********************/



/*******************/
/* Local Variables */
/*******************/



/*-------------------------------------------------------------------------
 * Function:    H5T__init_native
 *
 * Purpose:    Initialize pre-defined native datatypes from code generated
 *              during the library configuration by H5detect.
 *
 * Return:    Success:    non-negative
 *        Failure:    negative
 *
 * Programmer:    Robb Matzke
 *              Wednesday, December 16, 1998
 *
 *-------------------------------------------------------------------------
 */
herr_t
H5T__init_native(void)
{
    H5T_t    *dt = NULL;
    herr_t    ret_value = SUCCEED;

    FUNC_ENTER_PACKAGE

   /*
    *    3        2        1        0
    * SEEEEEEE EMMMMMMM MMMMMMMM MMMMMMMM
    * Implicit bit? yes
    */
    if(NULL == (dt = H5T__alloc()))
        HGOTO_ERROR(H5E_DATATYPE, H5E_NOSPACE, FAIL, "datatype allocation failed");
    dt->shared->state = H5T_STATE_IMMUTABLE;
    dt->shared->type = H5T_FLOAT;
    dt->shared->size = 4;
    dt->shared->u.atomic.order = H5T_ORDER_LE;
    dt->shared->u.atomic.offset = 0;
    dt->shared->u.atomic.prec = 32;
    dt->shared->u.atomic.lsb_pad = H5T_PAD_ZERO;
    dt->shared->u.atomic.msb_pad = H5T_PAD_ZERO;
dt->shared->u.atomic.u.f.sign = 31;
dt->shared->u.atomic.u.f.epos = 23;
dt->shared->u.atomic.u.f.esize = 8;
dt->shared->u.atomic.u.f.ebias = 0x0000007f;
dt->shared->u.atomic.u.f.mpos = 0;
dt->shared->u.atomic.u.f.msize = 23;
dt->shared->u.atomic.u.f.norm = H5T_NORM_IMPLIED;
dt->shared->u.atomic.u.f.pad = H5T_PAD_ZERO;
    if((H5T_NATIVE_FLOAT_g = H5I_register(H5I_DATATYPE, dt, FALSE)) < 0)
        HGOTO_ERROR(H5E_DATATYPE, H5E_CANTINIT, FAIL, "can't register ID for built-in datatype");
    H5T_NATIVE_FLOAT_ALIGN_g = 4;

   /*
    *    7        6        5        4
    * SEEEEEEE EEEEMMMM MMMMMMMM MMMMMMMM
    *    3        2        1        0
    * MMMMMMMM MMMMMMMM MMMMMMMM MMMMMMMM
    * Implicit bit? yes
    */
    if(NULL == (dt = H5T__alloc()))
        HGOTO_ERROR(H5E_DATATYPE, H5E_NOSPACE, FAIL, "datatype allocation failed");
    dt->shared->state = H5T_STATE_IMMUTABLE;
    dt->shared->type = H5T_FLOAT;
    dt->shared->size = 8;
    dt->shared->u.atomic.order = H5T_ORDER_LE;
    dt->shared->u.atomic.offset = 0;
    dt->shared->u.atomic.prec = 64;
    dt->shared->u.atomic.lsb_pad = H5T_PAD_ZERO;
    dt->shared->u.atomic.msb_pad = H5T_PAD_ZERO;
dt->shared->u.atomic.u.f.sign = 63;
dt->shared->u.atomic.u.f.epos = 52;
dt->shared->u.atomic.u.f.esize = 11;
dt->shared->u.atomic.u.f.ebias = 0x000003ff;
dt->shared->u.atomic.u.f.mpos = 0;
dt->shared->u.atomic.u.f.msize = 52;
dt->shared->u.atomic.u.f.norm = H5T_NORM_IMPLIED;
dt->shared->u.atomic.u.f.pad = H5T_PAD_ZERO;
    if((H5T_NATIVE_DOUBLE_g = H5I_register(H5I_DATATYPE, dt, FALSE)) < 0)
        HGOTO_ERROR(H5E_DATATYPE, H5E_CANTINIT, FAIL, "can't register ID for built-in datatype");
    H5T_NATIVE_DOUBLE_ALIGN_g = 8;

   /*
    *   15       14       13       12
    * SEEEEEEE EEEEEEEE MMMMMMMM MMMMMMMM
    *   11       10        9        8
    * MMMMMMMM MMMMMMMM MMMMMMMM MMMMMMMM
    *    7        6        5        4
    * MMMMMMMM MMMMMMMM MMMMMMMM MMMMMMMM
    *    3        2        1        0
    * MMMMMMMM MMMMMMMM MMMMMMMM MMMMMMMM
    * Implicit bit? yes
    */
    if(NULL == (dt = H5T__alloc()))
        HGOTO_ERROR(H5E_DATATYPE, H5E_NOSPACE, FAIL, "datatype allocation failed");
    dt->shared->state = H5T_STATE_IMMUTABLE;
    dt->shared->type = H5T_FLOAT;
    dt->shared->size = 16;
    dt->shared->u.atomic.order = H5T_ORDER_LE;
    dt->shared->u.atomic.offset = 0;
    dt->shared->u.atomic.prec = 128;
    dt->shared->u.atomic.lsb_pad = H5T_PAD_ZERO;
    dt->shared->u.atomic.msb_pad = H5T_PAD_ZERO;
dt->shared->u.atomic.u.f.sign = 127;
dt->shared->u.atomic.u.f.epos = 112;
dt->shared->u.atomic.u.f.esize = 15;
dt->shared->u.atomic.u.f.ebias = 0x00003fff;
dt->shared->u.atomic.u.f.mpos = 0;
dt->shared->u.atomic.u.f.msize = 112;
dt->shared->u.atomic.u.f.norm = H5T_NORM_IMPLIED;
dt->shared->u.atomic.u.f.pad = H5T_PAD_ZERO;
    if((H5T_NATIVE_LDOUBLE_g = H5I_register(H5I_DATATYPE, dt, FALSE)) < 0)
        HGOTO_ERROR(H5E_DATATYPE, H5E_CANTINIT, FAIL, "can't register ID for built-in datatype");
    H5T_NATIVE_LDOUBLE_ALIGN_g = 16;

    /* Set the native order for this machine */
    H5T_native_order_g = H5T_ORDER_LE;

done:
    if(ret_value < 0) {
        if(dt != NULL) {
            dt->shared = H5FL_FREE(H5T_shared_t, dt->shared);
            dt = H5FL_FREE(H5T_t, dt);
        } /* end if */
    } /* end if */

    FUNC_LEAVE_NOAPI(ret_value);
} /* end H5T__init_native() */
