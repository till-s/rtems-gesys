#ifndef RTEMS_VERSION_CHECKER_H
#define RTEMS_VERSION_CHECKER_H
/* Version checker macro; T.S, 2006 */

#include <rtems.h>

#ifndef RTEMS_VERSION_LATER_THAN
#define RTEMS_VERSION_LATER_THAN(ma,mi,re) \
	(    __RTEMS_MAJOR__  > (ma)	\
	 || (__RTEMS_MAJOR__ == (ma) && __RTEMS_MINOR__  > (mi))	\
	 || (__RTEMS_MAJOR__ == (ma) && __RTEMS_MINOR__ == (mi) && __RTEMS_REVISION__ > (re)) \
    )
#endif

#ifndef RTEMS_VERSION_ATLEAST
#define RTEMS_VERSION_ATLEAST(ma,mi,re) \
	(    __RTEMS_MAJOR__  > (ma)	\
	 || (__RTEMS_MAJOR__ == (ma) && __RTEMS_MINOR__  > (mi))	\
	 || (__RTEMS_MAJOR__ == (ma) && __RTEMS_MINOR__ == (mi) && __RTEMS_REVISION__ >= (re)) \
    )
#endif

#endif
