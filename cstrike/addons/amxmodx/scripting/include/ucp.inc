/* Ultra Core Protector Anti-Cheat System Functions
*
* Copyright © 2008-2010, UCP Team
*
* This file is provided as is (no warranties).
*
*/

/* Gets player ucpid. */
native ucp_id(index, ucpid[]);

/* Gets player authid generated from ucpid. */
native get_user_authid2(index, authid[], len);

/* Gets client build number */
native get_user_build(index, build[]);

/* Gets client OS */
native get_user_os(index, useros[]);
