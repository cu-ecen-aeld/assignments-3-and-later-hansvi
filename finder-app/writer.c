#include <stdio.h>
#include <syslog.h>
#include <stdlib.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <unistd.h>
#include <string.h>

int main(int argc, char *argv[])
{
	openlog(NULL, 0, LOG_USER);

	if (argc != 3)
	{
		syslog(LOG_ERR, "Usage: %s <writefile> <writestr>", argv[0]);
		exit(1);
	}
	syslog(LOG_DEBUG, "Writing %s to %s", argv[2], argv[1]);

	int fd = creat(argv[1], 0644);
	if (fd < 0)
	{
		syslog(LOG_ERR, "%s: %m", argv[1]);
		exit(1);
	}

	size_t len;
	ssize_t bytes_written;
	char *buf = argv[2];

	len = strlen(buf);
	while (len != 0)
	{
		bytes_written = write(fd, buf, len);
		if (bytes_written == -1)
		{
			syslog(LOG_ERR, "%s: %m", argv[1]);
			exit(1);
		}
		len -= bytes_written;
		buf += bytes_written;
	}

	return 0;
}
