#include <dirent.h>
#include <errno.h>
#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <unistd.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>

/* TODO:
 * The code is currently not thread-safe; it uses static
 * buffers. That should be fixed before it can be considered ready
 * for embedding in a multithreaded environment (i.e., iPhone).
 */

typedef struct {
    char *buf;
    int size;
    int capacity;
} textbuf;

#define LINEBUFSIZE 1024

static void sockprintf(int sock, char *fmt, ...);
static void tbwrite(textbuf *tb, const char *data, int size);
static void tbprintf(textbuf *tb, const char *fmt, ...);
static void do_get(int csock, const char *url);
static void do_post(int csock, const char *url);
static const char *canonicalize_url(const char *url);
static int open_item(const char *url, int post, FILE **file, int *filesize, DIR **dir);
static const char *get_mime(const char *ext);
static void http_error(int csock, int err);

static void read_line(int csock, char *buf, int bufsize) {
    int p = 0;
    int afterCR = 0;
    while (1) {
	int n = recv(csock, buf + p, 1, 0);
	if (n == -1) {
	    buf[p] = 0;
	    break;
	}
	if (afterCR) {
	    if (buf[p] == '\n') {
		buf[p] = 0;
		break;
	    } else {
		afterCR = 0;
		if (p < bufsize - 1)
		    p++;
	    }
	} else {
	    if (buf[p] == '\r') {
		afterCR = 1;
	    } else {
		if (p < bufsize - 1)
		    p++;
	    }
	}
    }
    buf[p] = 0;
}

void handle_client(int csock) {
    char *req;
    char *url;
    char *protocol;

    req = (char *) malloc(LINEBUFSIZE);
    if (req == NULL) {
	fprintf(stderr, "Memory allocation failure while allocating line buffer\n");
	shutdown(csock, SHUT_WR);
	return;
    }

    read_line(csock, req, LINEBUFSIZE);
    fprintf(stderr, "%s\n", req);

    url = strchr(req, ' ');
    if (url == NULL) {
	fprintf(stderr, "Malformed HTTP request: \"%s\"\n", req);
	shutdown(csock, SHUT_WR);
	free(req);
	return;
    }

    protocol = strchr(url + 1, ' ');
    if (protocol == NULL) {
	fprintf(stderr, "Malformed HTTP request: \"%s\"\n", req);
	shutdown(csock, SHUT_WR);
	free(req);
	return;
    }

    *url++ = 0;
    *protocol++ = 0;
    if (strncmp(protocol, "HTTP/", 5) != 0) {
	fprintf(stderr, "Unsupported protocol: \"%s\"\n", protocol);
	shutdown(csock, SHUT_WR);
	free(req);
	return;
    }

    if (strcmp(req, "GET") == 0)
	do_get(csock, url);
    else if (strcmp(req, "POST") == 0)
	do_post(csock, url);
    else
	fprintf(stderr, "Unsupported method: \"%s\"\n", req);
    shutdown(csock, SHUT_WR);
    free(req);
}

static void sockprintf(int sock, char *fmt, ...) {
    va_list ap;
    char text[LINEBUFSIZE];
    ssize_t sent;
    int err;
    va_start(ap, fmt);
    vsprintf(text, fmt, ap);
    sent = send(sock, text, strlen(text), 0);
    err = errno;
    if (sent != strlen(text))
	fprintf(stderr, "send() only sent %d out of %d bytes: %s (%d)\n", sent, strlen(text),
		strerror(err), err);
    va_end(ap);
}

static void tbwrite(textbuf *tb, const char *data, int size) {
    if (tb->size + size > tb->capacity) {
	int newcapacity = tb->capacity == 0 ? 1024 : (tb->capacity << 1);
	while (newcapacity < tb->size + size)
	    newcapacity <<= 1;
	char *newbuf = (char *) realloc(tb->buf, newcapacity);
	if (newbuf == NULL) {
	    /* Bummer! Let's just append as much as we can */
	    memcpy(tb->buf + tb->size, data, tb->capacity - tb->size);
	    tb->size = tb->capacity;
	} else {
	    tb->buf = newbuf;
	    tb->capacity = newcapacity;
	    memcpy(tb->buf + tb->size, data, size);
	    tb->size += size;
	}
    } else {
	memcpy(tb->buf + tb->size, data, size);
	tb->size += size;
    }
}

static void tbprintf(textbuf *tb, const char *fmt, ...) {
    va_list ap;
    char text[LINEBUFSIZE];
    va_start(ap, fmt);
    vsprintf(text, fmt, ap);
    tbwrite(tb, text, strlen(text));
    va_end(ap);
}

typedef struct dir_item {
    char *name;
    int size;
    int type; /* 0=unknown, 1=file, 2=dir */
    char mtime[64];
    struct dir_item *next;
} dir_item;

static int dir_item_compare(const void *va, const void *vb) {
    dir_item *a = *((dir_item **) va);
    dir_item *b = *((dir_item **) vb);
    return strcmp(a->name, b->name);
}

static void do_get(int csock, const char *url) {
    int err;
    FILE *file;
    int filesize;
    DIR *dir;
    char buf[LINEBUFSIZE];
    int n;

    url = canonicalize_url(url);
    if (url == NULL) {
	http_error(csock, 403);
	return;
    }

    err = open_item(url, 0, &file, &filesize, &dir);
    if (err != 200) {
	free((void *) url);
	http_error(csock, err);
	return;
    }

    if (file != NULL) {
	sockprintf(csock, "HTTP/1.0 200 OK\r\n");
	sockprintf(csock, "Connection: close\r\n");
	sockprintf(csock, "Content-Type: %s\r\n", get_mime(url));
	sockprintf(csock, "Content-Length: %d\r\n", filesize);
	sockprintf(csock, "\r\n");
	while ((n = fread(buf, 1, LINEBUFSIZE, file)) > 0)
	    send(csock, buf, n, 0);
	fclose(file);
    } else if (url[strlen(url) - 1] != '/') {
	sockprintf(csock, "HTTP/1.0 302 Moved Temporarily\r\n");
	sockprintf(csock, "Connection: close\r\n");
	sockprintf(csock, "Location: %s/\r\n", url);
	sockprintf(csock, "\r\n");
    } else {
	textbuf tb = { NULL, 0, 0 };
	struct dirent *d;
	struct dir_item *dir_list = NULL;
	int dir_length = 0;
	struct dir_item **dir_array;
	int i;

	tbprintf(&tb, "<html>\n");
	tbprintf(&tb, " <head>\n");
	tbprintf(&tb, "  <title>Index of %s</title>\n", url);
	tbprintf(&tb, "  <style type=\"text/css\">\n");
	tbprintf(&tb, "   td { padding-left: 10px }\n");
	tbprintf(&tb, "  </style>\n");
	tbprintf(&tb, " </head>\n");
	tbprintf(&tb, " <body>\n");
	tbprintf(&tb, "  <h1>Index of %s</h1>\n", url);
	tbprintf(&tb, "  <table><tr><th><img src=\"/icons/blank.gif\"></th><th>Name</th><th>Last modified</th><th>Size</th></tr><tr><th colspan=\"4\"><hr></th></tr>\n");
	tbprintf(&tb, "   <tr><td valign=\"top\"><img src=\"/icons/back.gif\"></td><td><a href=\"..\">Parent directory</a></td><td>&nbsp;</td><td align=\"right\">&nbsp;</td></tr>\n");
	while ((d = readdir(dir)) != NULL) {
	    struct stat s;
	    struct tm stm;
	    dir_item *di = (dir_item *) malloc(sizeof(dir_item));

	    if (strcmp(d->d_name, ".") == 0 || strcmp(d->d_name, "..") == 0)
		continue;
	    if (strlen(url) == 1)
		err = stat(d->d_name, &s);
	    else {
		char *p = (char *) malloc(strlen(url) + strlen(d->d_name) + 1);
		strcpy(p, url + 1);
		strcat(p, "/");
		strcat(p, d->d_name);
		err = stat(p, &s);
		free(p);
	    }
	    di->name = (char *) malloc(strlen(d->d_name) + 1);
	    strcpy(di->name, d->d_name);
	    if (err == 0) {
		localtime_r(&s.st_mtime, &stm);
		strftime(di->mtime, sizeof(di->mtime), "%d-%b-%Y %H:%M:%S", &stm);
		if (S_ISREG(s.st_mode)) {
		    di->type = 1;
		    di->size = s.st_size;
		} else if (S_ISDIR(s.st_mode))
		    di->type = 2;
		else
		    di->type = 0;
	    } else
		di->type = 0;
	    di->next = dir_list;
	    dir_list = di;
	    dir_length++;
	}

	dir_array = (dir_item **) malloc(dir_length * sizeof(dir_item *));
	for (i = 0; i < dir_length; i++) {
	    dir_array[i] = dir_list;
	    dir_list = dir_list->next;
	}

	qsort(dir_array, dir_length, sizeof(dir_item *), dir_item_compare);

	for (i = 0; i < dir_length; i++) {
	    dir_item *di = dir_array[i];
	    switch (di->type) {
		case 0:
		    tbprintf(&tb, "   <tr><td valign=\"top\"><img src=\"/icons/unknown.gif\"></td><td><a href=\"%s\">%s</a></td><td>?</td><td align=\"right\">?</td></tr>\n", di->name, di->name);
		    break;
		case 1:
		    tbprintf(&tb, "   <tr><td valign=\"top\"><img src=\"/icons/text.gif\"></td><td><a href=\"%s\">%s</a></td><td>%s</td><td align=\"right\">%d</td></tr>\n", di->name, di->name, di->mtime, di->size);
		    break;
		case 2:
		    tbprintf(&tb, "   <tr><td valign=\"top\"><img src=\"/icons/folder.gif\"></td><td><a href=\"%s\">%s</a></td><td>%s</td><td align=\"right\">-</td></tr>\n", di->name, di->name, di->mtime);
		    break;
	    }
	    free(di->name);
	    free(di);
	}
	free(dir_array);

	tbprintf(&tb, "   <tr><th colspan=\"4\"><hr></th></tr>\n");
	tbprintf(&tb, "   <tr><td colspan=\"4\"><form method=\"post\" enctype=\"multipart/form-data\">\n");
	tbprintf(&tb, "    Upload file:<p>\n");
	tbprintf(&tb, "    <input type=\"file\" name=\"filedata\"><p>\n");
	tbprintf(&tb, "    <input type=\"submit\" value=\"Submit\">\n");
	tbprintf(&tb, "   </form></td></tr>\n");
	tbprintf(&tb, "   <tr><th colspan=\"4\"><hr></th></tr></table>\n");
	tbprintf(&tb, "  <address>Free42 HTTP Server</address>\n");
	tbprintf(&tb, " </body>\n");
	tbprintf(&tb, "</html>\n");

	sockprintf(csock, "HTTP/1.0 200 OK\r\n");
	sockprintf(csock, "Connection: close\r\n");
	sockprintf(csock, "Content-Type: text/html\r\n");
	sockprintf(csock, "Content-Length: %d\r\n", tb.size);
	sockprintf(csock, "\r\n");
	send(csock, tb.buf, tb.size, 0);
	free(tb.buf);
	closedir(dir);
    }
    free((void *) url);
}

void do_post(int csock, const char *url) {
    char line[LINEBUFSIZE];
    char boundary[LINEBUFSIZE] = "";
    char c;
    int n;
    int blen;

    url = canonicalize_url(url);
    if (url == NULL) {
	http_error(csock, 403);
	return;
    }

    while (1) {
	read_line(csock, line, LINEBUFSIZE);
	if (strlen(line) == 0)
	    break;
	if (strncasecmp(line, "Content-Type:", 13) == 0) {
	    char *p = line + 13;
	    char q;
	    while (*p == ' ')
		p++;
	    if (strncmp(p, "multipart/form-data;", 20) != 0) {
		http_error(csock, 415);
		return;
	    }
	    p += 20;
	    while (*p == ' ')
		p++;
	    if (strncmp(p, "boundary=", 9) != 0) {
		http_error(csock, 415);
		return;
	    }
	    p += 9;
	    if (*p == '\'' || *p == '"')
		q = *p++;
	    else
		q = 0;
	    strcpy(boundary, "\r\n--");
	    strcat(boundary, p);
	    p = boundary;
	    while (*p != 0)
		p++;
	    if (q != 0 && p[-1] == q)
		*(--p) = 0;
	    blen = strlen(boundary);
	}
    }

    /* Now we're going to read the request body; this will be
     * delimited using the boundary we found above...
     */
    read_line(csock, line, LINEBUFSIZE);
    if (strlen(line) + 2 != blen || strncmp(line, boundary + 2, blen - 2) != 0) {
	http_error(csock, 415);
	return;
    }

    while (1) {
	/* Loop over message parts */
	char filename[LINEBUFSIZE] = "";
	textbuf tb;
	int bpos;

	while (1) {
	    /* Loop over part headers */
	    read_line(csock, line, LINEBUFSIZE);
	    if (strlen(line) == 0)
		break;
	    if (strncasecmp(line, "Content-Disposition: form-data; name=\"filedata\";", 48) == 0) {
		char *p = strstr(line + 48, "filename=");
		char *p2;
		char q;
		if (p == NULL) {
		    http_error(csock, 415);
		    return;
		}
		p += 9;
		if (*p == '\'' || *p == '"')
		    q = *p++;
		else
		    q = 0;
		p2 = p + strlen(p);
		while (p2 >= p)
		    if (*p2 == '\\' || *p2 == '/') {
			p = p2 + 1;
			break;
		    } else
			p2--;
		strcpy(filename, p);
		if (q != 0 && filename[strlen(filename) - 1] == q)
		    filename[strlen(filename) - 1] = 0;
	    }
	}

	/* Read part body until we find a "\r\n" followed by a boundary string */
	tb.buf = NULL;
	tb.size = 0;
	tb.capacity = 0;
	bpos = 0;

	while (1) {
	    char c;
	    int n = recv(csock, &c, 1, 0);
	    if (n != 1)
		break;
	    if (*filename != 0)
		tbwrite(&tb, &c, 1);
	    if (bpos == blen && (c == '\r' || c == '-'))
		bpos++;
	    else if (bpos == blen + 1 && (c == '\n' || c == '-'))
		bpos++;
	    else if (c == boundary[bpos])
		bpos++;
	    else if (c == boundary[0])
		bpos = 1;
	    else
		bpos = 0;
	    if (bpos == blen + 2) {
		/* Found the body delimiter! */
		if (*filename != 0) {
		    tb.size -= blen + 2;
		    strcpy(line, url + 1);
		    strcat(line, filename);
		    if (tb.size == 0)
			unlink(line);
		    else {
			FILE *f = fopen(line, "w");
			if (f == NULL) {
			    http_error(csock, 403);
			    free(tb.buf);
			    return;
			}
			fwrite(tb.buf, 1, tb.size, f);
			fclose(f);
		    }
		    free(tb.buf);
		}
		if (*filename != 0 || c == '-')
		    goto done;
		else
		    break;
	    }
	}
    }
    done:

    sockprintf(csock, "HTTP/1.0 302 Moved Temporarily\r\n");
    sockprintf(csock, "Connection: close\r\n");
    sockprintf(csock, "Location: %s\r\n", url);
    sockprintf(csock, "\r\n");
    free((void *) url);
}

static const char *canonicalize_url(const char *url) {
    /* This function:
     * enforces that the url starts with a "/"
     * substitutes "//" => "/"
     * substitutes "/./" => "/"
     * substitutes "/something/../" => "/"
     * substitutes trailing "/." => "/"
     * substitutes trailing "/something/.." => "/"
     * forbids ascending above docroot
     */
    char *ret, *dst;
    const char *src;
    int state;

    if (url[0] != '/')
	return NULL;
    ret = (char *) malloc(strlen(url) + 1);
    src = url;
    dst = ret;
    state = 0;

    while (1) {
	char c = *src++;
	*dst++ = c;
	if (c == 0) {
	    if (state == 2)
		/* Trailing "/." => "/" */
		dst[-2] = 0;
	    else if (state == 3) {
		/* Trailing "/.." */
		if (dst == ret + 4) {
		    /* Attempt to go to the parent of our docroot! */
		    free(ret);
		    return NULL;
		}
		dst -= 5;
		while (*dst != '/')
		    dst--;
		dst[1] = 0;
	    }
	    return ret;
	}
	switch (state) {
	    case 0:
		if (c == '/')
		    state = 1;
		break;
	    case 1:
		if (c == '/')
		    dst--; /* "//" => "/" */
		else
		    state = c == '.' ? 2 : 0;
		break;
	    case 2:
		if (c == '/') {
		    dst -= 2; /* "/./" => "/" */
		    state = 1;
		} else
		    state = c == '.' ? 3 : 0;
		break;
	    case 3:
		if (c == '/') {
		    /* Found "/../"; move back two slashes */
		    if (dst == ret + 4) {
			/* Attempt to go to the parent of our docroot! */
			free(ret);
			return NULL;
		    }
		    dst -= 6;
		    while (*dst != '/')
			dst--;
		    dst++;
		    state = 1;
		} else
		    state = 0;
		break;
	}
    }
}

static int open_item(const char *url, int post, FILE **file, int *filesize, DIR **dir) {
    struct stat statbuf;
    int err;

    /* We know that the url starts with '/'; strip it so that
     * it becomes a path relative to the current directory.
     * Of course the current directory should be set to docroot;
     * the -d command line option does this, and if it is
     * unspecified, it is the user's responsibility to run this
     * code after making sure some other way that the current
     * directory is docroot.
     */
    url++;
    if (strlen(url) == 0)
	url = ".";
    *file = NULL;
    *dir = NULL;

    /* TODO: if post == 1, it is OK for the item referenced by url
     * to not exist; in that case, we will create it (otherwise,
     * overwrite it, assuming it is a regular file), and the FILE we
     * return will have been opened for writing.
     */

    err = stat(url, &statbuf);
    if (err != 0) {
	err = errno;
	switch (err) {
	    case EACCES: return 403;
	    case EBADF: return 500;
	    case EFAULT: return 500;
	    case ELOOP: return 500;
	    case ENAMETOOLONG: return 404;
	    case ENOENT: return 404;
	    case ENOMEM: return 500;
	    case ENOTDIR: return 404;
	    default: return 500;
	}
    }

    if (S_ISREG(statbuf.st_mode)) {
	*file = fopen(url, "r");
	*filesize = statbuf.st_size;
	if (*file == NULL) {
	    /* We already know the file exists and is reachable, so
	     * we only check for EACCES; any other error is reported
	     * as an internal server error (500).
	     */
	    err = errno;
	    return err == EACCES ? 403 : 500;
	}
	return 200;
    } else if (S_ISDIR(statbuf.st_mode)) {
	*dir = opendir(url);
	if (*dir == NULL) {
	    /* We already know the file exists and is reachable, so
	     * we only check for EACCES; any other error is reported
	     * as an internal server error (500).
	     */
	    err = errno;
	    return err == EACCES ? 403 : 500;
	}
	return 200;
    } else
	return 403;
}

typedef struct {
    const char *ext;
    const char *mime;
} mime_rec;

static mime_rec mime_list[] = {
    { "gif", "image/gif" },
    { "jpg", "image/jpeg" },
    { "png", "image/png" },
    { "ico", "image/vnd.microsoft.icon" },
    { "txt", "text/plain" },
    { "htm", "text/html" },
    { "html", "text/html" },
    { "raw", "application/octet-stream" },
    { NULL, "application/octet-stream" }
};

static const char *get_mime(const char *filename) {
    int i = 0;
    int filenamelen = strlen(filename);
    int extlen;
    while (1) {
	mime_rec *mr = &mime_list[i++];
	if (mr->ext == NULL)
	    return mr->mime;
	extlen = strlen(mr->ext);
	if (filenamelen >= extlen && strcmp(filename + filenamelen - extlen, mr->ext) == 0)
	    return mr->mime;
    }
}

static void http_error(int csock, int err) {
    const char *msg;
    switch (err) {
	case 200: msg = "OK"; break;
	case 403: msg = "Forbidden"; break;
	case 404: msg = "Not Found"; break;
	case 415: msg = "Unsupported Media Type"; break;
	case 500: msg = "Internal Server Error"; break;
	case 501: msg = "Not Implemented"; break;
	default: msg = "Internal Server Error"; break;
    }
    sockprintf(csock, "HTTP/1.0 %d %s\r\n", err, msg);
    sockprintf(csock, "Connection: close\r\n");
    /* TODO: Descriptive response body */
    sockprintf(csock, "\r\n");
}

char ipname[256];
int ssock;

int begin_listen()
{
	int csock;
    struct sockaddr_in ca;	
	char cname[256];
	int err;
	
    while (1) {
		unsigned int n = sizeof(ca);
		csock = accept(ssock, (struct sockaddr *) &ca, &n);
		if (csock == -1) {
			err = errno;
			fprintf(stderr, "Could not accept connection from client: %s (%d)\n", strerror(err), err);
			return 1;
		}
		inet_ntop(AF_INET, &ca.sin_addr, cname, sizeof(cname));
		/*fprintf(stderr, "Accepted connection from %s\n", cname);*/
		handle_client(csock);
    }
    
	return 0;
}

int init(int argc, char *argv[]) {
    int i;
    int port = 9090;
    int backlog = 32;
    struct sockaddr_in sa;
    int err;

    for (i = 1; i < argc; i++) {
	if (strcmp(argv[i], "-p") == 0) {
	    if (i == argc - 1 || sscanf(argv[i + 1], "%d", &port) != 1) {
		fprintf(stderr, "Can't parse port number \"%s\"\n", argv[i + 1]);
		return 1;
	    }
	    i++;
	} else if (strcmp(argv[i], "-b") == 0) {
	    if (i == argc - 1 || sscanf(argv[i + 1], "%d", &backlog) != 1) {
		fprintf(stderr, "Can't parse backlog number \"%s\"\n", argv[i + 1]);
		return 1;
	    }
	    i++;
	} else if (strcmp(argv[i], "-d") == 0) {
	    if (i == argc - 1)
		err = -1;
	    else
		err = chdir(argv[i + 1]);
	    if (err != 0) {
		fprintf(stderr, "Can't chdir to docroot \"%s\"\n", argv[i + 1]);
		return 1;
	    }
	    i++;
	} else {
	    fprintf(stderr, "Unrecognized option: \"%s\"\n", argv[i]);
	    return 1;
	}
    }

    ssock = socket(AF_INET, SOCK_STREAM, 0);
    if (ssock == -1) {
	err = errno;
	fprintf(stderr, "Could not create socket: %s (%d)\n", strerror(err), err);
	return 1;
    }

    sa.sin_family = AF_INET;
    sa.sin_port = htons(port);
    sa.sin_addr.s_addr = INADDR_ANY;
    err = bind(ssock, (struct sockaddr *) &sa, sizeof(sa));
    if (err != 0) {
	err = errno;
	fprintf(stderr, "Could not bind socket to port %d: %s (%d)\n", port, strerror(err), err);
	return 1;
    }

    err = listen(ssock, backlog);
    if (err != 0) {
	err = errno;
	fprintf(stderr, "Could not listen (backlog = %d): %s (%d)\n", backlog, strerror(err), err);
	return 1;
    }

	inet_ntop(AF_INET, &sa.sin_addr, ipname, sizeof(ipname));	
    return 0;
}
