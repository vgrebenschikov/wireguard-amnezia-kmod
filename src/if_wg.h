/* SPDX-License-Identifier: ISC
 *
 * Copyright (c) 2019 Matt Dunwoodie <ncon@noconroy.net>
 *
 * Permission to use, copy, modify, and distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 * ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 * OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 *
 * $FreeBSD$
 */

#ifndef __IF_WG_H__
#define __IF_WG_H__

#include <sys/queue.h>
#include <sys/socket.h>
#include <sys/sx.h>

#include <net/if.h>
#include <netinet/in.h>
#include <netinet/udp_var.h>

#include "wg_cookie.h"
#include "wg_noise.h"

struct wg_data_io {
	char	 wgd_name[IFNAMSIZ];
	void	*wgd_data;
	size_t	 wgd_size;
};

struct wg_socket;
struct grouptask;

STAILQ_HEAD(wg_packet_list, wg_packet);

struct wg_queue {
	struct mtx		 q_mtx;
	struct wg_packet_list	 q_queue;
	size_t			 q_len;
};

struct wg_socket {
	struct socket	*so_so4;
	struct socket	*so_so6;
	uint32_t	 so_user_cookie;
	int		 so_fibnum;
	in_port_t	 so_port;
};

struct wg_softc {
    LIST_ENTRY(wg_softc)	 sc_entry;
    struct ifnet		*sc_ifp;
    int			 	 sc_flags;

    struct ucred		*sc_ucred;
    struct wg_socket	 	 sc_socket;

    TAILQ_HEAD(,wg_peer)	 sc_peers;
    size_t			 sc_peers_num;

    struct noise_local		*sc_local;
    struct cookie_checker	 sc_cookie;

    struct radix_node_head	*sc_aip4;
    struct radix_node_head	*sc_aip6;

    struct grouptask	 	 sc_handshake;
    struct wg_queue		 sc_handshake_queue;

    struct grouptask		*sc_encrypt;
    struct grouptask		*sc_decrypt;
    struct wg_queue		 sc_encrypt_parallel;
    struct wg_queue		 sc_decrypt_parallel;
    u_int			 sc_encrypt_last_cpu;
    u_int			 sc_decrypt_last_cpu;

    struct sx			 sc_lock;
};

#define WG_KEY_SIZE	32

#define SIOCSWG _IOWR('i', 210, struct wg_data_io)
#define SIOCGWG _IOWR('i', 211, struct wg_data_io)

#endif /* __IF_WG_H__ */
