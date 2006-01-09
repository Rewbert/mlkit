#include <stdlib.h>
#include <errno.h>
#include <signal.h>
#include "Posix.h"

struct syserr_entry srcErr[] = {
  {"EACCES",EACCES},
  {"E2BIG", E2BIG},
  {"EADDRINUSE",EADDRINUSE},
  {"EADDRNOTAVAIL",EADDRNOTAVAIL},
  {"EAFNOSUPPORT",EAFNOSUPPORT},
  {"EAGAIN",EAGAIN},
  {"EALREADY",EALREADY},
  {"EBADF",EBADF},
  {"EBADMSG",EBADMSG},
  {"EBUSY",EBUSY},
  {"ECANCELED",ECANCELED},
  {"ECHILD",ECHILD},
  {"ECONNABORTED",ECONNABORTED},
  {"ECONNREFUSED",ECONNREFUSED},
  {"ECONNRESET",ECONNRESET},
  {"EDEADLK",EDEADLK},
  {"EDESTADDRREQ",EDESTADDRREQ},
  {"EDOM",EDOM},
  {"EDQUOT",EDQUOT},
  {"EEXIST",EEXIST},
  {"EFAULT",EFAULT},
  {"EFBIG",EFBIG},
  {"EHOSTUNREACH",EHOSTUNREACH},
  {"EIDRM",EIDRM},
  {"EILSEQ",EILSEQ},
  {"EINPROGRESS",EINPROGRESS},
  {"EINTR",EINTR},
  {"EINVAL",EINVAL},
  {"EIO",EIO},
  {"EISCONN",EISCONN},
  {"EISDIR",EISDIR},
  {"ELOOP",ELOOP},
  {"EMFILE",EMFILE},
  {"EMLINK",EMLINK},
  {"EMSGSIZE",EMSGSIZE},
  {"EMULTIHOP",EMULTIHOP},
  {"ENAMETOOLONG",ENAMETOOLONG},
  {"ENETDOWN",ENETDOWN},
  {"ENETRESET",ENETRESET},
  {"ENETUNREACH",ENETUNREACH},
  {"ENFILE",ENFILE},
  {"ENOBUFS",ENOBUFS},
  {"ENODATA",ENODATA},
  {"ENODEV",ENODEV},
  {"ENOENT",ENOENT},
  {"ENOEXEC",ENOEXEC},
  {"ENOLCK",ENOLCK},
  {"ENOLINK",ENOLINK},
  {"ENOMEM",ENOMEM},
  {"ENOMSG",ENOMSG},
  {"ENOPROTOOPT",ENOPROTOOPT},
  {"ENOSPC",ENOSPC},
  {"ENOSR",ENOSR},
  {"ENOSTR",ENOSTR},
  {"ENOSYS", ENOSYS},
  {"ENOTCONN",ENOTCONN},
  {"ENOTDIR",ENOTDIR},
  {"ENOTEMPTY",ENOTEMPTY},
  {"ENOTSOCK",ENOTSOCK},
  {"ENOTSUP",ENOTSUP},
  {"ENOTTY",ENOTTY},
  {"ENXIO",ENXIO},
  {"EOPNOTSUPP",EOPNOTSUPP},
  {"EOVERFLOW",EOVERFLOW},
  {"EPIPE",EPIPE},
  {"EPERM",EPERM},
  {"EPROTO",EPROTO},
  {"EPROTONOSUPPORT",EPROTONOSUPPORT},
  {"EPROTOTYPE",EPROTOTYPE},
  {"ERANGE",ERANGE},
  {"EROFS",EROFS},
  {"ESPIPE",ESPIPE},
  {"ESRCH",ESRCH},
  {"ESTALE",ESTALE},
  {"ETIME",ETIME},
  {"ETIMEDOUT",ETIMEDOUT},
  {"ETXTBSY",ETXTBSY},
  {"EWOULDBLOCK",EWOULDBLOCK},
  {"EXDEV",EXDEV},
  {NULL, 1}
};

struct syserr_entry srcSig[] = {
  {"SIGHUP", SIGHUP},
  {"SIGINT", SIGINT},
  {"SIGQUIT", SIGQUIT},
  {"SIGILL", SIGILL},
  {"SIGABRT", SIGABRT},
  {"SIGFPE", SIGFPE},
  {"SIGKILL", SIGKILL},
  {"SIGSEGV", SIGSEGV},
  {"SIGPIPE", SIGPIPE},
  {"SIGALRM", SIGALRM},
  {"SIGTERM", SIGTERM},
  {"SIGUSR1", SIGUSR1},
  {"SIGUSR2", SIGUSR2},
  {"SIGCHLD", SIGCHLD},
  {"SIGCONT", SIGCONT},
  {"SIGSTOP", SIGSTOP},
  {"SIGTSTP", SIGTSTP},
  {"SIGTTIN", SIGTTIN},
  {"SIGTTOU", SIGTTOU},
  {"SIGBUS", SIGBUS},
  {"SIGPOLL", SIGPOLL},
  {"SIGPROF", SIGPROF},
  {"SIGSYS", SIGSYS},
  {"SIGTRAP", SIGTRAP},
  {"SIGURG", SIGURG},
  {"SIGVTALRM", SIGVTALRM},
  {"SIGXCPU", SIGXCPU},
  {"SIGXFSZ", SIGXFSZ},
  {NULL, -1},
};

int 
count(struct syserr_entry s[])
{
  int i = 0;
  while (s[i].name) i++;
  return i;
}

int
cmpName(const struct syserr_entry *k1, const struct syserr_entry *k2)
{
  return strcmp(k1->name, k2->name);
}

int
cmpInt (const struct syserr_entry *k1, const struct syserr_entry *k2)
{
  if (k1->number < k2->number) return -1;
  if (k1->number > k2->number) return 1;
  return 0;
}

int
main(int argc, char**argv)
{
  int j,i;
  j = count(srcErr);
  printf("/*  THIS FILE IS GENERATED BY gen_syserror  *\n *  DO NOT MANUALLY EDIT THIS FILE          */\n\n");
  printf("static const unsigned int sml_numberofErrors = %d;\n\n", j);
  printf("static struct syserr_entry syserrTableName[] = {\n");
  qsort(srcErr, j, sizeof(struct syserr_entry), cmpName);
  i = 0;
  while (i < j)
  {
    printf("  {\"%s\", %s},\n", srcErr[i].name, srcErr[i].name);
    i++;
  }
  printf("  {NULL, -1}\n};\n");

  qsort(srcErr,j,sizeof(struct syserr_entry), cmpInt);
  printf ("\nstatic struct syserr_entry syserrTableNumber[] = {\n");
  i = 0;
  while (i < j)
  {
    printf("  {\"%s\", %s},\n", srcErr[i].name, srcErr[i].name);
    i++;
  }
  printf("  {NULL, -1}\n};\n");

  j = count (srcSig);
  printf("\n\nstatic const unsigned int sml_numberofSignals = %d;\n\n", j);
  qsort(srcSig, j, sizeof(struct syserr_entry), cmpName);
  printf("static struct syserr_entry syssigTableNumber[] ={\n");
  i = 0;
  while (i < j)
  {
    printf("  {\"%s\", %s},\n", srcSig[i].name, srcSig[i].name);
    i++;
  }
  printf("  {NULL, -1}\n};\n");


  return EXIT_SUCCESS;
}