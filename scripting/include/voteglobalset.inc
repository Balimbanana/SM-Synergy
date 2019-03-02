#if defined _voteglobalset_included
 #endinput
#endif
#define _voteglobalset_included

bool voteinprogress = false;
Menu g_hVoteMenu = null;
#define VOTE_NO "###no###"
#define VOTE_YES "###yes###"

enum voteType
{
	question
}

new voteType:g_voteType = voteType:question;
