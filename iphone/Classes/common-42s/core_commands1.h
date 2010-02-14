/*****************************************************************************
 * Free42 -- an HP-42S calculator simulator
 * Copyright (C) 2004-2010  Thomas Okken
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License, version 2,
 * as published by the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, see http://www.gnu.org/licenses/.
 *****************************************************************************/

#ifndef CORE_COMMANDS1_H
#define CORE_COMMANDS1_H 1

#include "free42.h"
#include "core_globals.h"

int docmd_clx(arg_struct *arg) COMMANDS1_SECT;
int docmd_enter(arg_struct *arg) COMMANDS1_SECT;
int docmd_swap(arg_struct *arg) COMMANDS1_SECT;
int docmd_rdn(arg_struct *arg) COMMANDS1_SECT;
int docmd_chs(arg_struct *arg) COMMANDS1_SECT;
int docmd_div(arg_struct *arg) COMMANDS1_SECT;
int docmd_mul(arg_struct *arg) COMMANDS1_SECT;
int docmd_sub(arg_struct *arg) COMMANDS1_SECT;
int docmd_add(arg_struct *arg) COMMANDS1_SECT;
int docmd_lastx(arg_struct *arg) COMMANDS1_SECT;
int docmd_complex(arg_struct *arg) COMMANDS1_SECT;
int docmd_sto(arg_struct *arg) COMMANDS1_SECT;
int docmd_sto_div(arg_struct *arg) COMMANDS1_SECT;
int docmd_sto_mul(arg_struct *arg) COMMANDS1_SECT;
int docmd_sto_add(arg_struct *arg) COMMANDS1_SECT;
int docmd_sto_sub(arg_struct *arg) COMMANDS1_SECT;
int docmd_rcl(arg_struct *arg) COMMANDS1_SECT;
int docmd_rcl_div(arg_struct *arg) COMMANDS1_SECT;
int docmd_rcl_mul(arg_struct *arg) COMMANDS1_SECT;
int docmd_rcl_sub(arg_struct *arg) COMMANDS1_SECT;
int docmd_rcl_add(arg_struct *arg) COMMANDS1_SECT;
int docmd_fix(arg_struct *arg) COMMANDS1_SECT;
int docmd_sci(arg_struct *arg) COMMANDS1_SECT;
int docmd_eng(arg_struct *arg) COMMANDS1_SECT;
int docmd_all(arg_struct *arg) COMMANDS1_SECT;
int docmd_null(arg_struct *arg) COMMANDS1_SECT;
int docmd_asto(arg_struct *arg) COMMANDS1_SECT;
int docmd_arcl(arg_struct *arg) COMMANDS1_SECT;
int docmd_cla(arg_struct *arg) COMMANDS1_SECT;
int docmd_deg(arg_struct *arg) COMMANDS1_SECT;
int docmd_rad(arg_struct *arg) COMMANDS1_SECT;
int docmd_grad(arg_struct *arg) COMMANDS1_SECT;
int docmd_rect(arg_struct *arg) COMMANDS1_SECT;
int docmd_polar(arg_struct *arg) COMMANDS1_SECT;
int docmd_size(arg_struct *arg) COMMANDS1_SECT;
int docmd_quiet(arg_struct *arg) COMMANDS1_SECT;
int docmd_cpxres(arg_struct *arg) COMMANDS1_SECT;
int docmd_realres(arg_struct *arg) COMMANDS1_SECT;
int docmd_keyasn(arg_struct *arg) COMMANDS1_SECT;
int docmd_lclbl(arg_struct *arg) COMMANDS1_SECT;
int docmd_rdxdot(arg_struct *arg) COMMANDS1_SECT;
int docmd_rdxcomma(arg_struct *arg) COMMANDS1_SECT;
int docmd_clsigma(arg_struct *arg) COMMANDS1_SECT;
int docmd_clp(arg_struct *arg) COMMANDS1_SECT;
int docmd_clv(arg_struct *arg) COMMANDS1_SECT;
int docmd_clst(arg_struct *arg) COMMANDS1_SECT;
int docmd_clrg(arg_struct *arg) COMMANDS1_SECT;
int docmd_del(arg_struct *arg) COMMANDS1_SECT;
int docmd_clkeys(arg_struct *arg) COMMANDS1_SECT;
int docmd_cllcd(arg_struct *arg) COMMANDS1_SECT;
int docmd_clmenu(arg_struct *arg) COMMANDS1_SECT;
int docmd_clall(arg_struct *arg) COMMANDS1_SECT;
int docmd_percent(arg_struct *arg) COMMANDS1_SECT;
int docmd_pi(arg_struct *arg) COMMANDS1_SECT;
int docmd_to_deg(arg_struct *arg) COMMANDS1_SECT;
int docmd_to_rad(arg_struct *arg) COMMANDS1_SECT;
int docmd_to_hr(arg_struct *arg) COMMANDS1_SECT;
int docmd_to_hms(arg_struct *arg) COMMANDS1_SECT;
int docmd_to_rec(arg_struct *arg) COMMANDS1_SECT;
int docmd_to_pol(arg_struct *arg) COMMANDS1_SECT;
int docmd_ip(arg_struct *arg) COMMANDS1_SECT;
int docmd_fp(arg_struct *arg) COMMANDS1_SECT;
int docmd_rnd(arg_struct *arg) COMMANDS1_SECT;
int docmd_abs(arg_struct *arg) COMMANDS1_SECT;
int docmd_sign(arg_struct *arg) COMMANDS1_SECT;
int docmd_mod(arg_struct *arg) COMMANDS1_SECT;

#ifdef BIGSTACK
int docmd_drop(arg_struct *arg) COMMANDS1_SECT;
#endif

#endif
