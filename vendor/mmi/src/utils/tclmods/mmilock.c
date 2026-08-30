// ************************************************************************
// 
// Copyright (c) 1995-2002 Juniper Networks, Inc. All rights reserved.
// 
// Permission is hereby granted, without written agreement and without
// license or royalty fees, to use, copy, modify, and distribute this
// software and its documentation for any purpose, provided that the
// above copyright notice and the following three paragraphs appear in
// all copies of this software.
// 
// IN NO EVENT SHALL JUNIPER NETWORKS, INC. BE LIABLE TO ANY PARTY FOR
// DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES
// ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF
// JUNIPER NETWORKS, INC. HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH
// DAMAGE.
// 
// JUNIPER NETWORKS, INC. SPECIFICALLY DISCLAIMS ANY WARRANTIES,
// INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, AND
// NON-INFRINGEMENT.
// 
// THE SOFTWARE PROVIDED HEREUNDER IS ON AN "AS IS" BASIS, AND JUNIPER
// NETWORKS, INC. HAS NO OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT,
// UPDATES, ENHANCEMENTS, OR MODIFICATIONS.
// 
// ************************************************************************

/* Manage access contention for max/sue files among multiple
 * max/sue processes.  This function is called when a user
 * first modifies a max/sue file, so max/sue can print a warning.
 * Requirements:
 * - Catch both different users or the same user trying to modify the
 *   file in different max processes.
 * - If max/sue crashes, clean up quietly.
 * - Don't release the lock until the last user saves the file or quits,
 *   which means there may be multiple locks on each file.  For example,
 *   user A modifies the file.  Then user B modify the file, and gets
 *   a warning, but procedes anyway.  Eventually one of the users saves
 *   the file or exits.  The file must remain locked because the other
 *   user is still modifying it.
 *
 * We use a semaphore file (named by SEMA_FILE_NAME, below) containing records.
 * Each record contains a filename and user name.  The record is locked
 * with fcntl when file is modified, unlocked and cleared when max/sue
 * exits or saves the file.
 * Each time a max/sue file is modified, the inuse file is searched
 * for matching filenames.  If found, try to unlock it.  If it can
 * be unlocked, it means the invoking max/sue process died.
 * 
 * The first record in the .inuse file is reserved as a semaphore
 * to prevent multiple processes from trying to modify the .inuse
 * file simultaneously.
 */

/* Set STANDALONE_TEST to 1 to compile this file
 * as a stand-alone executable for testing.
 */
#define STANDALONE_TEST 0

#define SEMA_DEBUG 0

/***
 *** #include <stdio.h>
 *** #include <unistd.h>
 ***/
#include <tcl.h>
#include <stdlib.h>
#include <fcntl.h>
#include <limits.h>
#include <string.h>
#include <sys/types.h>
#include <sys/stat.h>

/* Old declaration method:
 * int MMITcl_SemaFileObjCmd(ClientData cd, Tcl_Interp *interp,
 *	int objc, Tcl_Obj *objv[]);
 */
Tcl_ObjCmdProc MMITcl_SemaFileObjCmd;

#define SEMA_KEY_SIZE 256
#define SEMA_USER_SIZE 100


#define SEMA_FILE_NAME ".mmi_files_inuse"

/* There is a potential bug if hostids on Suns and linux boxes collide.
 * Could use hostname to eliminate this miniscule possibility.
 */
struct sema_key {
    char key[SEMA_KEY_SIZE];
    char user[SEMA_USER_SIZE];
    int hostid;	/* Host id of lockers computer */
    int pid;	/* Process id of locker */
    int time;	/* Time lock was created */
    int locktype;	/* SEMA_CMD_LOCK_NON or SEMA_CMD_LOCK_EXCL */
    char cr[2]; /* Add a carriage return, just to make file prettier. */
};


/* There is one semaphore file in each directory where max/sue files
 * might be opened, so we keep them in a queue.
 */
struct sema_file_link {
    struct sema_file_link *next;
    struct stat stat;
    int lock_fd;
    int time;	/* Time file was opened */
    char lock_fn[PATH_MAX+2];
};
static struct sema_file_link *sema_file_head = NULL;

static char *sema_list = NULL;	/* Used for list sub-command */

static int sema_debug = 0;


#define FCNTL_TYPE_STRING(cmd) ( \
	    ((cmd)==F_SETLK) ? "F_SETLK" : ((cmd)==F_GETLK) ? "F_GETLK" : \
	    ((cmd)==F_WRLCK) ? "F_WRLCK" : ((cmd)==F_UNLCK) ? "F_UNLCK" : "?" )


/* Lock info for F_GETLK is left in static s_lock structure.
 */
static struct flock s_lock;
static int lock(int fd,int offset,int cmd,int type)
{
    int ret;
    s_lock.l_type = type;
    s_lock.l_whence = 0;
    s_lock.l_start = offset;
    s_lock.l_len = 1;		/* Lock one byte at offset */
    ret = fcntl(fd,cmd,&s_lock);
#if SEMA_DEBUG
    /* Note the l_sysid has only two values (0 or 32767 on a Sun)
     * to indicate if it is the local sun or some other.
     */
    if (sema_debug) fprintf(stderr,"fcntl(%d,%s,%s): ret=%d l_type=%d=%s l_pid=%d l_sysid=%d\n",
	    offset,
	    FCNTL_TYPE_STRING(cmd), FCNTL_TYPE_STRING(type),
	    ret,s_lock.l_type,FCNTL_TYPE_STRING(s_lock.l_type),s_lock.l_pid,s_lock.l_sysid);
#endif
    return ret;
}

/* Update key at offset.  Return 0 on success. */
static int update(int fd,int offset,char *key,char *user,int locktype)
{
    struct sema_key s_key;
#if SEMA_DEBUG
	if (sema_debug) fprintf(stderr,"update %d %s %s\n",offset,key,user);
#endif
    memset(&s_key,' ',sizeof(s_key));
    strcpy(s_key.key,key);
    strcpy(s_key.user,user);
    if (key[0] != 0) {
	s_key.pid = getpid();
	s_key.hostid = gethostid();
	s_key.time = time(0);
    }
    s_key.locktype = locktype;
    s_key.cr[1] = '\n';
    lseek(fd,offset,0);
    if (write(fd,&s_key,sizeof(s_key)) != sizeof(s_key)) {
#if SEMA_DEBUG
	if (sema_debug) fprintf(stderr,"write(%d) failed\n",offset);
#endif
	return -1;
    }
    return 0;
}


/* Return open file descriptor for lockfile, or -1 on error.
 * Can have multiple path names for a single file, so use inode number.
 */
static int sema_open_lock_file(char *lockfile, char *errbuf,int *ptime)
{
    struct stat statbuf;
    struct sema_file_link *flink;

    if (strlen(lockfile) >= PATH_MAX-1) {
	sprintf(errbuf,"lockfile name too long: %s",lockfile);
	return -1;
    }
    if (*lockfile == 0) {
	strcpy(errbuf,"null lockfile name!");
	return -1;
    }

    if (stat(lockfile,&statbuf) == 0) {
	/* File already exists.   See if we can find it in the linked list,
	 * meaning it is already open.
	 */
	for (flink = sema_file_head; flink != NULL; flink = flink->next) {
	    if (flink->stat.st_ino == statbuf.st_ino && flink->stat.st_dev == statbuf.st_dev) {
		*ptime = flink->time;
		return flink->lock_fd;
	    }
	}
    }

    /* Not found.  Open or create new lock file.
     */
#if SEMA_DEBUG
    if (sema_debug) fprintf(stderr,"Creating lock file: %s\n",lockfile);
#endif

    flink = (struct sema_file_link*)malloc(sizeof(struct sema_file_link));
    flink->time = time(0);
    flink->next = sema_file_head;
    sema_file_head = flink;
    strcpy(flink->lock_fn,lockfile);
    flink->lock_fd = open(lockfile,O_RDWR|O_CREAT,0777);
    if (stat(lockfile,&flink->stat) != 0) {
	if (flink->lock_fd == -1) {
	    sprintf(errbuf,"Could not create file: %s",lockfile);
	} else {
	    sprintf(errbuf,"Could not stat file: %s",lockfile);
	}
	return -1;
    }

    *ptime = flink->time;
    return flink->lock_fd;
}

/* General purpose inter-process semaphore function.
 * lock_file is the directory/filename of the file containing semaphores.
 * Key is the semaphore to lock, and user is the user doing the locking.
 * The semaphore is used to warn when two people are editing the
 * same file at the same time.
 * The locks are per-process, not per-user, since the a user could
 * try to edit the same file in two different max sessions.
 * However, the lock structure maintained by UNIX contains the PID of the
 * locking process, so it is not an argument here.  The user argument
 * is for diagnostic purposes only.
 *
 * Name of user who has key locked is returned in buffer pointed
 * to by locker, if non-NULL.
 *
 *        QUERY: query, do not lock;
 *           Returns: 0 not found, 1 previous lock found.
 *        LOCK_NON: lock non-exclusive, always succeeds.
 *           Returns: 0 no previous lock, 1 previous lock found,
 *           and returns the name of (one of the) user(s) who already
 *           had this key locked.
 *        LOCK_EXCL: lock key exclusive for this PID;
 *           Returns: 0 success, 1 failure: already locked.
 *	     Note: LOCK_EXCL and LOCK_NON both set write-locks, which
 *	     unix calls exclusive locks.  The difference is that LOCK_EXCL
 *           fails if there is already a lock on this key, and LOCK_NON
 *           allows multiple locks of same key.
 *        UNLOCK: unlock key owned by current PID;
 *	     Returns: 0 if not found, 1 if success.
 *        UNLOCK_ALL: unlock all locks owned by current PID.
 * RETURN: -1 on error; 0: lock not found; 1: success/lock found.
 * On error, err_msg points to a message about what went wrong.
 * If fnd_user is non-NULL, copy the name of the user who owns key into it.
 */
#define SEMA_CMD_QUERY 1
#define SEMA_CMD_LOCK_NON 2
#define SEMA_CMD_LOCK_EXCL 3
#define SEMA_CMD_UNLOCK 4
#define SEMA_CMD_UNLOCK_ALL 5
#define SEMA_CMD_LIST 6

#define SEMA_LOCK_STRING(locktype) \
	( (locktype) == SEMA_CMD_LOCK_EXCL ? "exclusive" : \
	  (locktype) == SEMA_CMD_LOCK_NON ? "shared"     : "?" )

static int sema_lock_int(char *lock_file, char *key, char *user,
	char *locker,char *errbuf,int cmd, int f_all,int f_self)
{
    struct sema_file_link *flink;
    struct sema_key s_key;
    char *cp;
    char *error = NULL;
    int ret_status = 0;
    int f_my_lock;
    int infd;
    int mypid = getpid();
    int myhostid = gethostid();
    int filetime;
    int offset, unused_offset = -1;
    int f_anykey = (cmd == SEMA_CMD_UNLOCK_ALL || cmd == SEMA_CMD_LIST);

    if (strlen(lock_file) >= PATH_MAX-1) {
	error = "filename too long";
	bad:
	strcpy(errbuf,error);
	return -1;
    }
    if (strlen(key) >= SEMA_KEY_SIZE-1) {
	error = "key too long";
	goto bad;
    }
    if (strlen(user) >= SEMA_USER_SIZE-1) {
	error = "user name too long";
	goto bad;
    }

    if (f_all) {
	/* Process all open semaphore files. */
	int ret;
	for (flink = sema_file_head; flink != NULL; flink = flink->next) {
	    ret = sema_lock_int(flink->lock_fn,key,user,locker,errbuf,cmd,0,f_self);
	    if (ret == -1) { return -1; }
	    if (ret == 1) { ret_status = 1; }
	}
	return ret_status;
    } else {
	infd = sema_open_lock_file(lock_file,errbuf,&filetime);
	if (infd == -1) return -1;
    }


    /* We want exclusive access to the file temporarily.
     * To accomplish this, lock the second byte (byte 1) of the file,
     * which is otherwise unused.
     */
    if (lock(infd,1,F_SETLK,F_WRLCK) == -1) {
	printf("Waiting for access to file %s...",lock_file);
	fflush(stdout);
	while (lock(infd,1,F_SETLKW,F_WRLCK) == -1) { continue; }
	printf("done, continuing.\n");
    }

    /* Look for the key.
     * Cases are:
     *  keys the same, users different;
     *  keys the same, users same, pid different - same user opening file again.
     *		action for both of the above is the same.
     *  keys the same, users same, pid same -bug
     */
    offset = - sizeof(struct sema_key);
    while (1) {
	int nread;
	offset += sizeof(struct sema_key);
	lseek(infd,offset,0);
	nread = read(infd,&s_key,sizeof(s_key));
#if SEMA_DEBUG
	if (nread&&sema_debug) fprintf(stderr,"offset %d key %s nread=%d\n",offset,s_key.key,nread);
#endif
	if (nread != sizeof(struct sema_key)) {
	    /* End of file; key not found */
	    break;
	}

	if (s_key.key[0] == 0) {
	    if (unused_offset == -1) { unused_offset = offset; }
	    continue;
	}

	if (f_anykey || strcmp(s_key.key,key) == 0) {
	    /* Key found.
	     * Figure out who has it locked.  Set f_my_lock if I own this lock.
	     * GETLK will return lock info iff some other process has it locked.
	     * Note: the fcntl documentation is unclear about what fcntl
	     * returns in this case.  On sun it returns 0 if
	     * no lock exists or -1 if a previous lock exists.  The return
	     * status is irrelevant; the info returned in the s_lock buffer
	     * is all we need.
	     */
	    (void) lock(infd,offset,F_GETLK,F_WRLCK);

	    if (s_lock.l_type != F_UNLCK) {
		/* Locked by another process. */
		f_my_lock = 0;
	    } else {
		/* No current lock by any other system on this key.
		 * See if we have it locked ourselves.
		 * GETLK will not detect our own locks.
		 */
		if (s_key.hostid == myhostid && s_key.pid == mypid) {
		    /* This key looks like it was created by this process.
		     * Only possible exception is if another process with
		     * the same pid died and left keys around.
		     */
		    if (s_key.time < filetime) {
			/* This key was created before we opened the file!
			 * It was created by a process that just happened
			 * to have our pid on our system,
			 * and that died without unlocking this key.
			 */
			goto unused;
		    } else {
			/* This is our lock
			 */
			f_my_lock = 1;
		    }
		} else {
		    unused:
		    /* There is a key, but it is not locked.
		     * The locking process probably died.
		     * Clear the key, and remember this file position.
		     */
#if SEMA_DEBUG
		    if (sema_debug) fprintf(stderr,"unlocking key\n");
#endif
		    update(infd,offset,"","",0);
		    if (unused_offset == -1) { unused_offset = offset; }
		    continue;
		}
	    }


	    if (cmd == SEMA_CMD_UNLOCK_ALL) {
		/* Only unlock the file if it is our pid.
		 * This will also succeed if lock was owned by another PID
		 * that died.
		 */
		if (f_my_lock) {
		    if (lock(infd,offset,F_SETLK,F_UNLCK) != -1) {
			/* Successful unlock.  Clear the key, too. */
			update(infd,offset,"","",0);
			ret_status = 1;
		    }
		}
		continue;
	    }
	    if (cmd == SEMA_CMD_LIST) {
		char *sp, buf1[PATH_MAX+2], buf2[PATH_MAX+200];
		/* Get the lock_file directory into buf1. */
		strcpy(buf1,lock_file);
		if (sp = strrchr(buf1,'/')) {*sp = 0;}
		sprintf(buf2,"{%s %s %x:%d %s %s} ",
		  buf1,s_key.key,s_key.hostid,s_key.pid,s_key.user,
		  SEMA_LOCK_STRING(s_key.locktype));
		sema_list = (char*)realloc(sema_list,strlen(sema_list)+strlen(buf2) + 10);
		strcat(sema_list,buf2); 
		ret_status = 1;
		continue;
	    }

	    /* There is already a lock on this key.
	     * Return locking user to caller.
	     * Prefer a user name different from current user.
	     */
	    if (f_my_lock && !f_self) {
		switch (cmd) {
		case SEMA_CMD_QUERY:
		    /* Dont report our own lock */
		    continue;
		case SEMA_CMD_LOCK_NON:
		    /* Dont report our own lock */
		    continue;
		case SEMA_CMD_LOCK_EXCL:
		    if (s_key.locktype == SEMA_CMD_LOCK_EXCL) {
			 /* We already have an exclusive lock,
			  * which means it is the only lock that
			  * exists on this file.  Since user requested
			  * not to report our own locks, we are done.
			 goto done;
		    } else {
			/* Trying to set an exclusive lock,
			 * but this PID already has a non-exclusive lock.
			 * What we SHOULD do is change it to an
			 * exclusive lock only if no one else has
			 * a non-exclusive lock.  But I dont support this.
			 * So, just continue on to see if someone else
			 * has a non-shared lock, and if so, we will
			 * return it to the user.
			 */
			continue;
		    }
		}
	    }

	    if (locker && (ret_status == 0 || strcmp(locker,user) == 0)) {
		sprintf(locker,"%s %s",s_key.user,SEMA_LOCK_STRING(s_key.locktype));
	    }

	    switch (cmd) {
	    case SEMA_CMD_QUERY:
		ret_status = 1;  /* Key found. */
		goto done;
	    case SEMA_CMD_LOCK_EXCL:
		ret_status = 1;  /* Key already locked */
		goto done;
	    case SEMA_CMD_LOCK_NON:
		ret_status = 1;  /* Previously locked, but who cares */
		if (s_key.locktype == SEMA_CMD_LOCK_EXCL) {
		    /* Key already locked exclusively.  Do not add another lock.
		     */
		    goto done;
		}
		continue;
	    case SEMA_CMD_UNLOCK:
		/* If this is my lock, unlock it.
		 * This will fail only if there is a bug in this code.
		 */
		if (f_my_lock) {
		    if (lock(infd,offset,F_SETLK,F_UNLCK) == 0) {
			ret_status = 1; /* successful unlock */
			update(infd,offset,"","",0);
		    } else {
			error = "Could not unlock file I thought I owned";
			goto done;
		    }
		}
		continue;

	    default:
		error = "unrecognized flag";
		goto done;
	    }
	}
    }

    if (cmd == SEMA_CMD_LOCK_EXCL || cmd == SEMA_CMD_LOCK_NON) {
	/* Add key to file.  Used unused slot, if any.
	 */
	if (unused_offset >= 0) { offset = unused_offset; }
	if (update(infd,offset,key,user,cmd) != 0) {
	    error = "write to lock file failed";
	    goto bad;
	}
	if (lock(infd,offset,F_SETLK,F_WRLCK) == -1) {
	    error = "fcntl failed";
	    goto bad;
	}
    }

    done:
    /* Release the lock on byte 1 */
    lock(infd,1,F_SETLK,F_UNLCK);
    if (error) {
	strcpy(errbuf,error);
	return -1;
    }
    return ret_status;
}

static int isdir(char *filename)
{
    struct stat statbuf;
    if (stat(filename,&statbuf) != 0) return 0;
    return statbuf.st_mode & S_IFDIR;
}

/* Manipulate semaphore locks on filenames.
 * Syntax:
 *	sema_file lock -file <filename> [-user <username>] [-report_self]
 *	sema_file lock_shared -file <filename> [-user <username>] [-report_self]
 *	sema_file query -file <filename> [-report_self]
 *	sema_file unlock -file <filename>
 *	sema_file unlock_all [-dir <directory>]
 *	sema_file list [-dir <directory>]
 *
 * 	<filename> is the name of a file to lock.
 *		The file does not need to exist.  In fact, this argument can
 *		more properly be considered a string of the form "directory/key",
 *		where <directory> (default ".") is where the lock file will be created,
 *		and <key> is any string representing a key to be locked.
 * 	<username> is the user who wants to lock the file.
 *		The lock is actually owned by the PID, not the user,
 *		because the same user could try to lock the same
 *		file in two different programs.  This username is basically
 *		just a comment that is saved only for reporting purposes if another
 *		PID tries to lock the same file.
 * 	The possible actions are:
 *	    "lock": sets an exclusive lock on the specified <filename>
 *		for the current PID.
 *		If a lock already exists, returns a two element
 *		list: "user locktype" and no additional lock is set.
 *		The <username> is saved for reporting to other PIDS. 
 *		If you try to re-lock an existing lock, it will
 *		be reported as a pre-existing lock if -report_self,
 *		otherwise the lock will just succeed and over-write
 *		the existing lock.  The -report_self flag applies only
 *		to requests by the same PID.  If user starts another
 *		PID (another copy of sue or max) and tries to do
 *		the lock the same file, that will be reported
 *		regardless of -report_self.
 *	    "lock_shared": sets a non-exclusive lock.
 *		If a no exclusive lock already exists,
 *		sets a new shared lock for the specified user.
 *		There can be any number of shared locks on the same file.
 *		Returns two element list: "user locktype" if a
 *		previous lock existed.
 *		A query or lock call will return any one of the users
 *		who have a shared lock.  It will not always be the first one.
 *	    "unlock": unlocks specified file for current PID.
 *	    "unlock_all": unlocks all files for current PID.
 *		If no <directory> is specified, all locks set by the
 *		current process are released.
 *		If a <directory> is specified, only locks on files
 *		in that directory are released.
 *	    "query": Returns a two element list of: "user locktype",
 *		or "" if none.  If the lock was set by the calling
 *		PID, and -report_self is not specified, it will not be reported.
 *		If it is a shared lock, any one of the lockers will be returned.
 *	    "list": Returns a list of current locks.
 *		If a <directory> argument is specified, all locks
 *		in that directory are returned, regardles of who set them.
 *		If no <directory> argument is given, all locks set by any PID
 *		in any directory ever mentioned to sema_file by this PID are returned.
 *	    "debug" num - set debug flag to num (0 or 1).
 *
 * Returns:
 *	"" on success, or the previous user name if another
 * 	user had previously locked this file.
 *	If an error occurs, a tcl error is thrown to the caller, which can
 *	be caught with the tcl "catch" command.
 * Notes:
 *	The user's own name may be returned if the user already
 *	has that file locked in a different PID.
 *
 *	You should not do a "query" to determine if a lock exists
 *	before doing a "lock".
 *	This creates a race condition between the time you do the "query" and
 *	when you do the "lock".  Instead, just try to do the "lock", which
 *	will return the previous locker if a lock already exists.
 *
 *	If a process dies, its locks are automatically released.
 *	The orphaned lock records in the lock file are cleaned up the
 *	next time any PID does any kind of locking or query operation.
 *
 *	The locking file is created in the same directory as <filename>.
 *	If <filename> is a path, the locking file is created in that
 *	directory.  It is an error if the locking file can not be created,
 *	for example, if user has insufficient privileges in that directory.
 *	But in that case, the user should probably not be trying
 *	to modify a sue/max file in that directory anyway.
 *	The error can be caught using the tcl catch function.
 *	The directory returned by "list" might not match the directory
 *	in filename exactly, but it will be synona-mouse.
 *
 *	If the semaphore file is busy, a message is printed to stdout
 *	and the function waits for the file to be available.
 *	This should be nearly instantaneous, unless there is a bug in this code.
 *
 *	Changing your own lock type is not supported, because I
 *	dont anticipate anyone wanting it.  That is,
 *	you can not do a lock_shared, then later a lock, on the
 *	same key to convert a shared lock to an exclusive lock.
 *	Instead, you would have to release your shared lock first,
 *	which creates a potential race condition with other users.
 */
int MMITcl_SemaFileObjCmd(ClientData cd, Tcl_Interp *interp,
	int objc, Tcl_Obj * CONST objv[])
{
    char *arg_file = NULL;
    char *arg_user = NULL;
    char *arg_dir = NULL;
    char f_self = 0;
    char *cmd;
    int icmd;

    char lockfile[PATH_MAX+2];
    char locker[SEMA_USER_SIZE+2];
    char key[PATH_MAX+2];
    char errbuf[PATH_MAX+100];
    char *cp;
    int f_all_dirs = 0;	/* TRUE to process all lock files */
    int ret;

    /* Ignore first argument in objv,objc; it is the proc name */
    objc--; objv++;

    /* Might be 1 to 3 args.
     */
    if (objc < 1) {
	syntax:
	Tcl_SetResult(interp,
	"syntax: sema_file lock|unlock|unlock_all|query|list [-file filename] [-user username] [-report_self]",TCL_STATIC);
	return TCL_ERROR;
    }

    cmd = Tcl_GetStringFromObj(objv[0], NULL);
    objc--; objv++;

    /* Consume option arguments */
    while (objc > 0) {
	char *option = Tcl_GetStringFromObj(objv[0],NULL);
	objc--; objv++;
	if (strcmp(option,"-file")==0) {
	    if (objc < 1) { goto syntax; }
	    arg_file = Tcl_GetStringFromObj(objv[0],NULL);
	    if (strlen(arg_file) >= PATH_MAX-1) {
		Tcl_SetResult(interp,"sema_file: filename too long",TCL_STATIC);
		return TCL_ERROR;
	    }
	    if (*arg_file == 0) {
		Tcl_SetResult(interp,"sema_file: invalid filename argument",TCL_STATIC);
		return TCL_ERROR;
	    }
	    objc--; objv++;
	} else if (strcmp(option,"-user")==0) {
	    if (objc < 1) { goto syntax; }
	    arg_user = Tcl_GetStringFromObj(objv[0],NULL);
	    objc--; objv++;
	} else if (strcmp(option,"-dir")==0) {
	    if (objc < 1) { goto syntax; }
	    arg_dir = Tcl_GetStringFromObj(objv[0],NULL);
	    if (strlen(arg_dir) >= PATH_MAX-1) {
		Tcl_SetResult(interp,"sema_file: filename too long",TCL_STATIC);
		return TCL_ERROR;
	    }
	    if (*arg_dir == 0) {
		Tcl_SetResult(interp,"sema_file: invalid filename argument",TCL_STATIC);
		return TCL_ERROR;
	    }
	    objc--; objv++;
	} else if (strcmp(option,"-report_self")==0) {
	    f_self = 1;
	}
    }

    /* Look at the first argument.
     */
    if (strcmp(cmd,"query")==0) {
	icmd = SEMA_CMD_QUERY;
	if (arg_file == NULL) {
	    missing_file:
	    Tcl_SetResult(interp,
		"sema_file: missing -file filename",TCL_STATIC);
	    return TCL_ERROR;
	}
	if (arg_dir) {
	    bad_option:
	    Tcl_SetResult(interp,"sema_file: bad options",TCL_STATIC);
	    return TCL_ERROR;
	}
    } else if (strcmp(cmd,"lock_shared")==0) {
	icmd = SEMA_CMD_LOCK_NON;
	if (arg_file == NULL) { goto missing_file; }
	if (arg_dir != NULL) { goto bad_option; }
    } else if (strcmp(cmd,"lock")==0) {
	icmd = SEMA_CMD_LOCK_EXCL;
	if (arg_file == NULL) { goto missing_file; }
	if (arg_dir != NULL) { goto bad_option; }
    } else if (strcmp(cmd,"unlock")==0) {
	icmd = SEMA_CMD_UNLOCK;
	if (arg_file == NULL) { goto missing_file; }
	if (arg_dir != NULL) { goto bad_option; }
	if (f_self) { goto bad_option; }
    } else if (strcmp(cmd,"unlock_all")==0) {
	icmd = SEMA_CMD_UNLOCK_ALL;
	if (arg_dir == NULL) { goto bad_option; }
	if (arg_file != NULL) { goto bad_option; }
	if (f_self) { goto bad_option; }
    } else if (strcmp(cmd,"list")==0) {
	icmd = SEMA_CMD_LIST;
	if (arg_dir == NULL) { goto bad_option; }
	if (arg_file != NULL) { goto bad_option; }
	if (f_self) { goto bad_option; }
	/* Initialize the list */
	sema_list = (char*)malloc(2);
	sema_list[0] = 0;
    } else if (strcmp(cmd,"debug")==0) {
	if (objc != 2) {
	    Tcl_SetResult(interp,
		"sema_file: syntax: sema_file debug value",TCL_STATIC);
	    return TCL_ERROR;
	}
	Tcl_GetIntFromObj(interp, objv[1], &sema_debug);
	return TCL_OK;

    } else {
	Tcl_SetResult(interp,
	    "sema_file: unrecognized command (first) argument",TCL_STATIC);
	return TCL_ERROR;
    }

    /* Check for left over unconsumed arguments */
    if (objc != 0) {
	goto syntax;
    }

    /* Make up a user name if none given.
     * Only used by lock, lock_shared subcommands.
     */
    if (arg_user == NULL) {
	arg_user = getenv("USER");
    }
    if (arg_user == NULL) {
	arg_user = getenv("LOGNAME");
    }
    if (arg_user == NULL) {
	/* We will just save the entire home directory for reporting.
	 * At least it will identify the user conclusively.
	 */
	arg_user = getenv("HOME");
    }
    if (arg_user == NULL) {
	arg_user = "unknown";
    }

    /* Put directory part of filename in lockfile, and filename tail in key.
     */
    if (icmd == SEMA_CMD_LIST || icmd == SEMA_CMD_UNLOCK_ALL) {
	if (arg_dir) {
	    /* The arg was a directory.  Use it as specified.
	     */
	    strcpy(lockfile,arg_dir);
	    cp = &lockfile[strlen(lockfile)-1];
	    if (*cp == '/') { *cp = 0; }
	    key[0] = 0;
	} else {
	    /* No -dir arg, will search all open dirs. */
	    f_all_dirs = 1;
	}
    } else {
	/* The -file arg may be just a filename or "directory/filename"
	 */
	strcpy(lockfile,arg_file);
	if (cp = strrchr(lockfile,'/')) {
	    strcpy(key,cp+1);
	    *cp = 0;
	} else {
	    /* No directory specified */
	    strcpy(lockfile,".");
	    strcpy(key,arg_file);
	}
    }

    /* Add lock file name onto lockfile.
     */
    strcat(lockfile,"/");
    strcat(lockfile,SEMA_FILE_NAME);

    locker[0] = 0;

    ret = sema_lock_int(lockfile,key,arg_user,locker,errbuf,
	icmd,f_all_dirs,f_self);

#if SEMA_DEBUG
    if (sema_debug) fprintf(stderr,"sema_lock_int(%s,%s,%s,%d) returns:(%d,%s)\n",
	lockfile,key,arg_user,icmd,ret,locker);
#endif

    if (ret == -1) {
	/* Error */
	char errbuf2[PATH_MAX+200];
	bad:
	sprintf(errbuf2, "sema_file %s error: %s", cmd,errbuf);
	Tcl_SetResult(interp,errbuf2,TCL_VOLATILE);
	return TCL_ERROR;

    } else if (icmd == SEMA_CMD_LIST) {
	Tcl_SetResult(interp,sema_list,TCL_VOLATILE);
	free(sema_list);
    } else if (ret == 1) {
	/* Success of query, or previous lock found.  Return locker user name */
	Tcl_SetResult(interp,locker,TCL_VOLATILE);
    } else if (ret == 0) {
	/* No lock found. Return empty string. */
	Tcl_SetResult(interp,"",TCL_STATIC);
    }

    return TCL_OK;
}


#if MAKE_PACKAGE

/* This is necessary to compile this file as a shared object
 * that can be loaded dynamically by the tcl load command.
 */
int Mmi_sema_package_Init(Tcl_Interp *interp)
{

  Tcl_CreateObjCommand(interp, "sema_file", MMITcl_SemaFileObjCmd, NULL, NULL);

  return TCL_OK;

}
#endif


#if STANDALONE_TEST
/* 3/23/01 Note: This code has probably eroded.
 * Manipulate a semaphore for user on the specified file.
 * Return NULL if no previous lock, or previous user name if a
 * semaphore already existed on this file.
 * Action: 0: lock; 1: unlock; 2: unlock all owned by pid.
 */
char *sema_file(char *fn, char *user, int action)
{
    char dirname[PATH_MAX+2];
    char key[PATH_MAX+2];
    static char locker[SEMA_USER_SIZE+2];
    char *err_msg = NULL;
    char *cp;
    int cmd, ret;

    if (strlen(fn) >= PATH_MAX-1) {
	fprintf(stderr,"file_lock: filename too long\n");
	return NULL;
    }

    /* Put directory part of fn in dirname, and filename in key.
     */
    strcpy(dirname,fn);
    if (cp = strrchr(dirname,'/')) {
	strcpy(key,cp+1);
	*cp = 0;
    } else {
	/* No directory specified */
	strcpy(dirname,".");
	strcpy(key,fn);
    }

    /* Add lock file name onto dirname.
     */
    strcat(dirname,"/");
    strcat(dirname,SEMA_FILE_NAME);

    switch (action) {
    case 0: cmd = SEMA_CMD_LOCK_NON; break;
    case 1: cmd = SEMA_CMD_UNLOCK; break;
    case 2: cmd = SEMA_CMD_UNLOCK_ALL; break;
    }

    ret = sema_lock_int(dirname,key,user,locker,&err_msg,cmd,0,0);

    if (ret == -1) {
	fprintf(stderr,"error locking %s key=%s user=%s: %s\n",
	    dirname,key,user,err_msg);
	return NULL;
    }
    if (ret == 1) {
	return locker;
    }
    return NULL;
}


main(int argc,char **argv)
{
    char *getenv();
    char *action, *key, *result;
    int cmd;
    int delay = 0;
    char *user = getenv("USER");
    if (user == NULL) { user = "unknown"; }

    argc--; argv++;
    if (argc == 0) {
	syntax:
	printf("Syntax: test [-delay_time] action key [user]\n");
	printf("action can be: lock, unlock, unlock_all\n");
	exit(2);
    }

    if (argv[0][0] == '-') {
	delay = atoi(&argv[0][1]);
	argc--; argv++;
    }

    action = argv[0];
    if (strcmp(action,"lock") == 0) {
	cmd = 0;
    } else if (strcmp(action,"unlock") == 0) { 
	cmd = 1;
    } else if (strcmp(action,"unlock_all") == 0) {
	cmd = 2;
    } else {
	goto syntax;
    }

    argc--; argv++;
    if (argc == 0) { goto syntax; }
    key = argv[0];

    argc--; argv++;
    if (argc != 0) { user = argv[0]; }

    result = sema_file(key,user,cmd);
    printf("result: %s\n", result ? result : "NULL");

    if (delay) { sleep(delay); }

}
#endif
