#!/usr/bin/perl
#
# forth		J. W. Wooten	01/18/96
#	$Source: /Users/woo/cvsrep/perl-forth/forth.pl,v $
#	$Revision: 1.13 $
#	$Author: woo $			$Date: 2015/02/07 20:14:37 $
#	$Locker:  $
#
# Copyright (C) J. W. Wooten and Oak Ridge National Laboratory 1996
# Permission is granted to reproduce the document in any way providing
# that it is distributed for free, except for any reasonable charges for
# printing, distribution, staff time, etc.  Direct commercial
# exploitation is not permitted.  Extracts may be made from this
# document providing an acknowledgment of the original source is
# maintained.
#
#	$Log: forth.pl,v $
#	Revision 1.13  2015/02/07 20:14:37  woo
#	updates to vector functions
#
#	Revision 1.12  2013/12/14 21:24:31  woo
#	Minor changes in Hello print.
#
#	Revision 1.11  2012/09/12 21:05:19  woo
#	Added plotxy to oddball and tested
#
#	Revision 1.10  2012/09/06 00:23:54  woo
#	Rewrote write to use a block in memory and then write it on flush.
#
#	Revision 1.9  2012/08/31 01:24:18  woo
#	Fixed problem with locating buffer for different files.
#	Still have to find buffer # in list.
#	flush not implemented yet.
#	plot working okay.
#
#	Revision 1.8  2012/08/25 20:43:40  woo
#	Added stub for graphics using gnuplot and a threaded search function.
#	Working on getting vocabulary working right and forget to leave so
#	that it is executable afterwards
#
#	Revision 1.7  2012/07/09 21:01:01  woo
#	Edited the do load to become load
#
#	Revision 1.6  2012/07/09 20:45:00  woo
#	Edited the Revision and the log to try to get it to be automatic
#
#	Revision 1.6  2012/07/09 20:28:51  woo
#	Added an init to try to later auto load forth.dict
#
#
#	Revision 1.5  2002-06-24 18:27:27-04  woo
#	changed intro to give date and last update author
#
#	Revision 1.4  2002-06-24 18:24:29-04  woo
#	put in '$Date: 2015/02/07 20:14:37 $'
#
#	Revision 1.3  2002-06-24 18:23:19-04  woo
#	tried '$Revision: 1.13 $'
#
#	Revision 1.2  2002-06-24 18:20:11-04  woo
#	tried to do Revision
#
#	Revision 1.1  2002-06-24 18:19:23-04  woo
#	Added mod % function and comment about forth.dict
#
#	Revision 1.0  2002-06-24 18:01:15-04  woo
#	Initial revision
#
# Revision 1.5  96/01/31  16:39:43  woo
# Fixed most functions, got FORGET working
# Haven't integrated ?search into outer interpreter yet.
#
# Revision 1.4  96/01/30  16:41:03  woo
# Fixed problem with +LOOP and prettied up tracing
#
# Revision 1.3  96/01/30  12:44:40  woo
# Fixed abort problem, now recovers correctly.
#
# Revision 1.2  96/01/29  17:21:42  woo
# added token, many others
# abort is messing up DP and stack
#
# Revision 1.1  96/01/18  14:15:27  woo
# Initial revision
#
#

$VERSION = '$Revision: 1.13 $';
$DATE = '$Date: 2015/02/07 20:14:37 $';
$LAST_AUTHOR = '$Author: woo $';
$DICT="forth.dict";
#
$err_msg[1] = "Compilation only, use in definition\n";
$err_msg[2] = "Execution only\n";
$err_msg[3] = "Conditionals not paired\n";
$err_msg[4] = "Definition not finished\n";
$err_msg[5] = "In protected dictionary\n";
$err_msg[6] = "Use only when loading\n";
$err_msg[7] = "Off current editing screen\n";
$err_msg[8] = "Declare vocabulary\n";
$err_msg[9] = "Range error\n";
$err_msg[10] = "No buffers allocated\n";
$err_msg[11] = "No file opened for writing\n";
$err_msg[12] = "Block not found\n";
$err_msg[13] = "No filename in block for write\n";
#
$WORD_LENGTH = 8; # for 64 bit machines
$dict{'CURRENT'} = 1;
$vars{'CURRENT'} = 4;
$dict{'DP'} = 5;
$vars{'DP'} = 8;
$dict{'CORE'} = 9;
$vars{'CORE'} = 12;
$dict{'LAST'} = 13;
$vars{'LAST'} = 16;
$dict{'ASPACE'} = 17;
$vars{'ASPACE'} = 19;
$dict{'RT_PAREN'} = 21;
$vars{'RT_PAREN'} = 23;
$dict{'QUOTE'} = 25;
$vars{'QUOTE'} = 27;
$stack[0] = 0;
#
$stack[1] = "CURRENT";	# header
$stack[2] = 0;		# link address
$stack[3] = "goto var";	# code address
$stack[4] = 12;		# addr of variable in current vocab, initially CORE
#
$stack[5] = "DP";
$stack[6] = 1;
$stack[7] = "goto var";
$stack[8] = 29;		# next free address
#
$stack[9] = "CORE";
$stack[10] = 5;
$stack[11] = "goto var";
$stack[12] = 25;		# last address in the CORE vocab
#
$stack[13] = "LAST";	# last definition in stack
$stack[14] = 9;
$stack[15] = "goto var";
$stack[16] = 25;
#
$stack[17] = "ASPACE";
$stack[18] = 13;
$stack[19] = "goto const";
$stack[20] = ' ';
#
$stack[21] = "RT_PAREN";
$stack[22] = 17;
$stack[23] = "goto const";
$stack[24] = ')';
#
$stack[25] = "QUOTE";
$stack[26] = 21;
$stack[27] = "goto const";
$stack[28] = '"';
#
&def_var("CONTEXT",12);
&def_var("IMMED",0);
&def_var("COMPILER",0);
#&def("colon","&colon");
&def("semi","semi");
&def("next","_next");
&def("execute","execute");
&def("quit","quit");
&def("search","search");
&def("immediate","immediate");
$addr_execute = $dict{&vocab("execute")} + 2;
$addr_semi = $dict{&vocab("semi")} + 2;
&def(";code","semicode");
&immed;
&def("drop","drop");
&def("drop2","drop2");
&def("push","_push");
&build("dup","drop","push","push");
&def("+","add");
&def("*","mult");
&def("/","div");
&def("%","mod_div");
def("fix","fix");
&def("values","_values");
&def(".","dot");
&def("cr","nl");
&def("BL", "blank");
&def("pi", "pi");
&def("bits","bits");
&def("hello","hello");
&def("init","init");
&def("names","names");
&def("prt_dict","prt_dict");
&def("trace_dict","trace_dict");
&def("trace_fcn","trace_fcn");
&def("n_prt","n_prt");
&def("type","type");
&def("exec","_exec");
&def("outer","outer");
&def("abort","abort");
$addr_exec = $dict{&vocab("exec")} + 2;
&def("literal","literal");
$addr_lit = $dict{&vocab("literal")} + 2;
&def("constant","constant");
&def("variable","variable");
&def("@","at");
&def("!","store");
&def("+!","plus_store");
&def("array","array");
&def_var("MODE",0);
&def_var("STATE",0);
&def_var("START",1);
&def_var("BASE",10);
&def_var("LOADING",0);
&def_var("delim"," ");
&def(":","_colon");
&def(";","_semi");
&immed;
&def(",;","dep_semi");
&def("create","create");
&def("HERE","here");
&def("allot","allot");
&def("minus","minus");
&def(",","_deposit");
&def(">R","pushR");
&def("R>","Rpop");
&def("R","R");
&def("over","over");
&def("rot","rot");
&def("swap","swap");
&def("-find","_find");
&def("?comp","_comp");
&def("?pairs","_pairs");
&def("?error","_error");
&def("0=","zequal");
&def("=","equal");
&def("DP!","dp_store");
&def("DPSET","dp_set");
&def(">","_gt");
&def("0BRANCH","zbranch");
&def("BRANCH","branch");
&def("token","_token");
&def_var("delim"," ");
&def("eol", "_eol");

&def("load","load");
&def(";S","semi_s");
&def("[","lbracket");
&immed;
&def("]","rbracket");
&immed;
&def("'","_tick");
&immed;
&def("compile","compile");
&def("[compile]","_compile");
&immed;
&def("?search","qsearch");
&build("LATEST","CURRENT","@","@");
&build("ENTRY","LATEST");
&def("question","question");
&def("<builds","builds");
&def("_does","_does");
&def("does>", "does");
&immed;
&def("(do)","_do");
&def("(loop)","_loop");
&def("(+loop)","_ploop");
&def("tracing","tracing");
&def("searching","searching");
&build('0set',0,'!');
&def('-dup','_dup');

&def("open", "_open_in");
&def("close", "_close");
&def("read", "_read");
&def("fopen", "fopen");
&def("write", "_write");
&def("flush", "_flush");	# write out edited buffers, mark as unedited
#def("clear-buffer","clear_buffer"); # clear out a buffer
#def("release", "release"); # n -> --, release buffer n (warn if edited?)
def("obtain", "obtain"); # -- -> --, create an empty buffer and set blk to it's buffer number $nextblk?
def("release", "release"); # -- -> --, release the current buffer in blk, put most used in blk
def("file!", "fname_store"); # file! str -> --, store the str as the filename of the current buffer
def("setfile","_set_file"); # str setfile stores the str as the filename
def("\".\"", "_concat");
def(">str", "_tostr");
def("indexOf", "_indexOf");
def("//", "_split");

$nextblk = 0;
&def_var("blk",0);
&def("block", "_block");
&def("blocks", "_blocks");
&def("(line)", "_line");
&def("erase", "_erase_line");
&def("line!", "_line_store");
&build("-line", "(line)", "type");
&def("lines", "_lines");
&def("update", "update");
&def("dump-buffer", "dumpBuffer");
&def("isEdited", "isEdited");

&def("count", "_count");
&def("perl", "_perl");
&def("system", "_system");

&def_var("x-label","x-label");
&def_var("y-label", "y-label");
&def_var("plt-title","Demo Sin(x) Plot");
&def_var("xlabel_font", "Courier,14");
&def_var("ylabel_font", "Courier,10");
&def_var("title_font", "CourierBold,18");
&def_var("xsize" ,1);
&def_var("ysize", 1);
&def_var("data_file", "/Users/woo/Desktop/gnuplot");
&def_var("plt_str", "sin(x)/x");
&def_var("scaling", "set autoscale");
&def_var("xtics", 20);
&def_var("grid", "set grid xtics ytics");
&def_var("key", "set nokey");
#
&def("plot","plot");
&def("open_gnuplot","open_gnuplot");
&def("plotit","plotit");
&def("gnuplot_command","gnuplot_command");

@buffers = ();

$stack[$vars{"DP"}] = $#stack+1;
$dp_hold = $#stack;
$last_header = $stack[16];
&_start;


$wa = $dict{&vocab("init")} + 2;
push(@ret_addr,$wa);
$ip = $dict{&vocab("execute")} + 2;
goto run;
#

#	$ip	Instruction Register.
#	$wa	Word Addr Register
#	$ca	Code Addr Register
#
#	@ret_addr	Return Stack
#
#	@values		Stack for Values
#
#	@files		Stack for load files
#

sub def		# define word that is internal sub or label
{
	$dp_hold = $#stack;
	$last_header = $stack[$vars{'LAST'}];
	$stack[$vars{'LAST'}] = $stack[$vars{'DP'}];
	push(@stack,@_[0]);
	$loc=1; write if $tracing;
	push(@stack,$stack[$stack[$vars{'CURRENT'}]]);
	$loc=2; write if $tracing;
	$stack[$stack[$vars{'CURRENT'}]] = $stack[$vars{'DP'}];
	if (@_[1] =~ /^&/)	{
		$addr = "@_[1]";
	} else	{
		$addr = "goto @_[1]";
	}
	@dict{@_[0]} = $stack[$vars{'LAST'}];
	push(@stack,$addr);
	$loc=3; write if $tracing;
	$stack[$vars{'DP'}] = $#stack+1;
}

sub def_var	{		# def variable with val
	&def(@_[0],"var");
	push(@stack,@_[1]);		# store initial value
	@vars{@_[0]} = $#stack;
	$stack[$vars{"DP"}] = $#stack+1;
}

init:			# init the system (maybe load forth.dict?)
	print "Initializing\n";
	@files = ();
	goto hello;

hello:			# print hello message at startup
	print "FORTH in PERL!\n";
	print "\tVersion: $VERSION";
	print "\n\tAuthor: woo\@shoulderscorp.com";
	print "\n\tLast Updated by: $LAST_AUTHOR on $DATE";
	print "\n\tnames will list words in dictionary.";
	print "\n\tload $DICT for more functions";
	print "\n\tor, oddball.dict for oddball";
	print "\n";
#	goto _next;
	goto abort;

quit:			# quit forth program
	print " bye\n";
	exit;

stkempty:
	print "Stack Underflow...aborting\n";
abort:			# abort execution, empty stack, restart
	@ret_addr=();
	@values=();
	@files=();
	$stack[$vars{'delim'}] = " ";
	$#stack=$dp_hold;
	$stack[$vars{'MODE'}] = 0;
	$stack[$vars{'STATE'}] = 0;
	$stack[$vars{'LAST'}] = $last_header;
	$stack[$vars{'DP'}] = $dp_hold+1;
	$stack[$vars{'LOADING'}] = 0;
	$wa = $dict{&vocab("outer")} + 2;
	push(@ret_addr,$wa);
	$ip = $dict{&vocab("execute")} + 2;
	#print "Aborting---------------------\n";
	#&prt_dict;
	#print "wa=",$wa," ip=",$ip,"\n";
	goto run;

sub colon	{
	push(@ret_addr,$ip);	# push instr ptr onto return addr stack
	$ip = $wa; 		$loc=4; write if $tracing;
	goto _next;
}

semi:
	goto _exec if ($#ret_addr==0);
	$ip = pop(@ret_addr);	$loc=5; write if $tracing;
_next:
	$wa = $stack[$ip++];
run:
				$loc=7; write if $tracing;
	$ca = $stack[$wa++];
	eval($ca);

execute:
	$wa = pop(@values);	$loc=8; write if $tracing;
	goto run;

sub chk_stack
{
	local ($args) = @_;

	return if $#values+1 >= $args;
	$num = $#values+1;
	print "$word expects $args items...Only $num on stack\n";
	goto stkempty;
}

sub pop	{
	&chk_stack(1);
	$last = pop(@values);
	return;
}


drop2:			# m n drop2 -> null
	&pop;
drop:			# n drop -> null
	&pop;
	goto _next;

_push:			# push -> push value last onto stack
	push(@values,$last);
	goto _next;

_dup:			# n -dup -> n n if n != 0, else 0
	goto _next if $values[$#values] == 0;
	push(@values,$values[$#values]);
	goto _next;

dot:			# n . -> print top entry on stack -> null
	print $values[$#values]," ";
	goto drop;

bits:			# bits n  -> print bits of n -> null
	$a = &token(' ');
	print unpack('B*',$a)," ";
	goto _next;

nl:			# -> print nl symbol
	print "\n";
	goto _next;

blank:		# -> put a blank on the stack
	push(@values, " ");
	goto _next;

pi:			# -> put value of pi on the stack
	push(@values, "3.1415926526728");
	goto _next;

add:			# m n + -> m+n
	&chk_stack(2);
	$values[$#values-1] += $values[$#values];
	goto drop;

mult:			# m n * -> m*n
	&chk_stack(2);
	$values[$#values-1] *= $values[$#values];
	goto drop;

div:			# m n / -> m/n
	&chk_stack(2);
	$dividend = $values[$#values];
	if( $dividend < 1.0e-12 )
	{
	    $dividend = 1.0e-12;
	}
	$values[$#values-1] /= $dividend;
	goto drop;

fix:			# fn -> int
	&chk_stack(1);
	$values[$#values] = int($values[$#values]+0.5);
	goto _next;

mod_div:		# m n % -> m mod n
	&chk_stack(2);
	$values[$#values-1] %= $values[$#values];
	goto drop;

_values:		# values -> list parameter stack leave untouched
	&values;
	goto _next;

sub values	{
	print "\nValue Stack\n";
	for ($i=$#values;$i>=0;$i--)	{
		print $i,") ",$values[$i],"\n";
	}
	return;
}

sub vocab	{
		$fnd = @_[0];
}

tracing:		# m tracing -> null, 0 ends, 1 starts
	&pop;
	$tracing = $last;
	goto _next;

searching:		# m searching -> null, 0 ends, 1 starts search trace
	&pop;
	$searching = $last;
	goto _next;

names:			# names -> null, prints names in $dict
	print "\nName Stack\n";
	foreach $val (sort keys(%dict))	{
		print $val,"-->",$dict{$val},"\n";
	}
	goto _next;

sub prt_dict	{
	print "\nReturn Stack";
		for($i=$#ret_addr;$i>=0;$i--)	{
			print $i,")",$ret_addr[$i],"\n";
				}
	print "\nDict Stack\n";
	for($i=$#stack;$i>=0;$i--)	{
	# split off vocab byte
	# print name with flag to right if immed and which vocab
		print $i,") ",($immed_flag{$stack[$i]} == 1)? 1 : " "," ",$stack[$i],"\t\t","\n";
	}
}

prt_dict:		# prt_dict -> null, prints entire dict (raw)
	&prt_dict;
	goto _next;

sub prt_n	{
	print "\nDict Stack\n";
	&pop;
	$k = $last;
	&pop;
	$s = $last;
	for($i=0;$i<$k;$i++)	{
		print $s,") ",$stack[$s],"\n";
		$s--;
	}
}

n_prt:		# m c n_prt -> null, starting at m print c stack items
	&prt_n;
	goto _next;

trace_fcn:	# ' word trace_fcn -> null, trace of word
	&_trace_fcn;
	goto drop;

sub _trace_fcn	{	# given wa on value stack, trace definition
	local ($ptr);

	$ptr = $values[$#values]-2;
	print "Tracing $stack[$ptr] at $ptr\n";
		if ($stack[$ptr+2] eq "&colon")	{
			for($i=$ptr+3;$stack[$i] != $addr_semi;$i++)	{
				print "$i)   ->",$stack[$stack[$i]-2],"\n";
			if ($stack[$stack[$i]-2] =~ /literal/)	{
				$j=$i+1;
				print "$j) lit=",$stack[$i+1],"\n";
				$i++;
				}
			if ($stack[$stack[$i]-2] =~ /const/)	{
				$j=$i+1;
				print "$j) con=",$stack[$i+1],"\n";
				$i++;
				}
			if ($stack[$stack[$i]-2] =~ /0BRANCH/)	{
				$j=$i+1;
				print "$j) j->",$stack[$i+1],"\n";
				$i++;
				}
			if ($stack[$stack[$i]-2] =~ /BRANCH/)	{
				$j=$i+1;
				print "$j) j->",$stack[$i+1],"\n";
				$i++;
				}
			}
			print "$i)   ->",";\n";
			return;
		}
		if ($stack[$ptr+2] eq "goto var")	{
			print "   x=",$stack[$ptr+3],"\n";
			return;
		}
		if ($stack[$ptr+2] eq "goto const")	{
			print "   c=",$stack[$ptr+3],"\n";
			return;
		}
		if ($stack[$ptr+2] eq "goto arr")	{
			$dim = $stack[$ptr+3];
			print "  dim=",$dim,"\n";
			$i=$dim;
			$ptr = $ptr+4;
			while($i--)	{
				$off = $dim-$i-1;
				print "    $off) $stack[$ptr++]\n";
			}
			return;
		}
		if ($stack[$ptr+2] eq "semi")	{

			print "   ->",";\n";
			return;
		}
		print "   code: $stack[$ptr+2]\n";
		return;
	}

trace_dict:		# CURRENT @ @ trace_dict -> null, trace words in CURRENT
	print "\nList Definitions\n";
	$p =pop(@values);
	while($p > 0)	{
		push(@values,$p+2);
		&_trace_fcn;
		pop(@values);
_incptr:	$p = $stack[$p+1];
	}
	print $stack[0],"\n";
	goto _next;


sub _start	{
	$stack[$addr_execute] = $addr_exec;
	return;
}

sub build	{	# build a word (internal use, no header)
	&def(@_[0],"&colon");
		shift(@_);
	while(@_)	{
		$name = @_[0];
		# here do a search for the $name in the proper vocabulary
		$adr = $dict{&vocab($name)};
		if(!$adr)	{
			push(@stack,$addr_lit);
			push(@stack,$name);
		} else	{
			push(@stack,$adr + 2);
			}
		shift(@_);
		}
	push(@stack,$addr_semi);
	$stack[$vars{"DP"}] = $#stack+1;
	$last_header = $stack[$vars{'LAST'}];
	$dp_hold = $#stack;
}

sub deposit	{	# deposite code, internal
	push(@stack,$values[$#values]);
	$stack[$vars{"DP"}] = $#stack+1;
}

_deposit:		# value , -> dep value in dict.
	&chk_stack(1);
	&deposit;
	goto drop;

literal:		# literal -> value following in dict when executing
	push(@values,$stack[$ip++]);
	goto _next;

const:			# const -> run time behavior of constant
	push(@values,$stack[$wa]);
	goto _next;

var:			# var -> run time behavior of variable
	push(@values,$wa);
	goto _next;

arr:			# arr -> run time behavior of array
	push(@values,$wa);
	goto _next;

sub immed	{
	$last_current = $stack[$stack[$vars{'CURRENT'}]];
	$old_immed = $stack[$vars{'IMMED'}];
	$stack[$stack[$vars{'CURRENT'}]] = $stack[$last_current+1];
	$stack[$last_current+1] = $old_immed;
	$stack[$vars{'IMMED'}] = $last_current;
	$stack[$vars{'COMPILER'}] = $last_current;
	$immed_flag{$stack[$last_current]} = 1;
}

immediate:		# mark last defined word as immediate
	&immed;
	goto _next;

constant:		# val constant name -> name puts val on stack
	&chk_stack(1);
	&def(&token(' '),"const");
	&deposit;
	goto drop;

variable:		# val variable name -> name puts addr on stack
	&chk_stack(1);
	&def(&token(' '),"var");
	&deposit;
	goto drop;

at:			# var-name @	-> puts val of name on stack
	$values[$#values] = $stack[$values[$#values]];
	goto _next;

store:			# val var-name ! -> store val in var-name
	&chk_stack(2);
	$stack[$values[$#values]] = $values[$#values-1];
	goto drop2;

plus_store:		# val var-name +! -> adds val to that stored
	&chk_stack(2);
	$stack[$values[$#values]] += $values[$#values-1];
	goto drop2;

array:			# length array-name -> makes array-name fills with 0
				# array-name puts address of dim of array on stack
				# array-name 1 + puts address of 0-th element of array on stack
				# 10 array x 5 array 3 + ! puts 5 into the 2nd element of array
				# array 3 + ? will print the 5 from that location
				# BTW, floating point works automatically
	&chk_stack(1);
	&def(&token(' '),"arr");
	$len = $values[$#values];
	&deposit;	# store length as first item
	while($len > 0)	{
		push(@values,0);
		&deposit;
		$len--;
		}
	$stack[$vars{"DP"}] = $#stack+1;
	goto _next;

sub _smudge	{
	if( $searching )	{
	 	my @str = split (//,@_[0]);
		my $chr = shift(@str);
		$chr = chr( ord($chr) ^ 0b1000000);
#		print "\n",$chr," ",ord($chr),"\n";
		unshift(@str, $chr);
		return join('',@str);
	}
		return @_[0];
	}

_colon:			# : new-word  -> starts defining new word
	$stack[$vars{'CONTEXT'}] = $stack[$vars{'CURRENT'}];
	$stack[$vars{'MODE'}] = 1;	# set to compile mode = true
	$last_header = $stack[$vars{'LAST'}];

create:			# create header for word
	&def(&_smudge(&token(' ')),"&colon"); # toggle top bit
	# append the vocabulary number to the right hand end of the word
	# search gets the vocabulary and tacks it on when searching.
	# displaying the word only shows up to last byte, prt_dict shows last byte translated to vocab name
	goto _next;

_semi:			# ; -> immediate - terminate definition of word
	push(@stack,$addr_semi);
	$stack[$vars{'MODE'}] = 0;	# set to compile mode = false
	$stack[$vars{'STATE'}] = 0;	# set STATE = false
	$stack[$vars{"DP"}] = $#stack+1;
	$last_header = $stack[$vars{'LAST'}];
	$stack[$stack[$vars{'LAST'}]]=&_smudge($stack[$stack[$vars{'LAST'}]]);
	$dp_hold = $#stack;
	goto _next;

dep_semi:		# deposit ; into dictionary
	goto _semi;

_find:		# -find following name in context dict
		#  put addr of name on stack & true or false
	$word = &token(' ');
	push(@values,$stack[$stack[$vars{'CONTEXT'}]]);
	&search;
	goto _goit if $values[$#values] == 1;
	goto _goit if($stack[$vars{'CONTEXT'}] == $stack[$vars{'CURRENT'}]);
	&pop;
	push(@values,$stack[$stack[$vars{'CURRENT'}]]);
	&search;
_goit:	goto _next;

_tick:			# ' word, immed causes word to be found and wa put on
			#	stack.  Abort if not found
	$word = &token(' ');
	push(@values,$stack[$stack[$vars{'CONTEXT'}]]);
	&search;
	&pop;
	goto goit if $last == 1;
	push(@values,$stack[$stack[$vars{'CURRENT'}]]);
	&search;
	&pop;
	goto question unless $last == 1;
goit:	$values[$#values] += 2;
	goto _next;

search:		# na search -> find word last input starting at na
	&search;
	goto _next;

sub search	{
	&pop;		# pop off starting addr of vocabulary being searched
	$wa = $last;
	$name = $word;
#	print "\nStarting at $wa, looking for $name\n";
	while($wa != '')	{
	if ($stack[$wa] eq $name) {
		push(@values,$wa);
		push(@values,1);
		return;
		}
	$wa = $stack[$wa+1];
	}
	push(@values,0);
	return;
}

here:			# HERE -> returns pres addr of end of dictionary
	push(@values,$stack[$vars{'DP'}]);
	goto _next;

dp_set:		# addr -> null, DP AND stack adjusted to be size addr
	&chk_stack(1);
	$#stack = $values[$#values]-1;
	$stack[$vars{"DP"}] = $#stack+1;
	goto drop;

dp_store:		# val addr DP! -> null, val stored at addr
	&chk_stack(2);
	$stack[$values[$#values]] = $values[$#values-1];
	goto drop2;

allot:			# val allot -> null, moves dict ptr by top of stack
	&chk_stack(1);
	$#stack += $values[$#values];
	$stack[$vars{"DP"}] = $#stack+1;
	goto drop;

minus:			# val - -> -val
	&chk_stack(1);
	$values[$#values] = - $values[$#values];
	goto _next;

pushR:			# n >R -> null, push tos to ret stack
	&chk_stack(1);
	push(@ret_addr,$values[$#values]);
	goto drop;

Rpop:			# R> -> ret_addr, pop ret_addr to tos
	push(@values,pop(@ret_addr));
	goto _next;

R:			# R -> ret_addr, copy ret_addr on tos
	push(@values,$ret_addr[$#ret_addr]);
	goto _next;

rot:			# 3 2 1 rot -> 1 3 2
	&chk_stack(3);
	$last = $values[$#values];
	$values[$#values] = $values[$#values-2];
	$values[$#values-2] = $values[$#values-1];
	$values[$#values-1] = $last;
	goto _next;

over:			# 3 2 1 over -> 3 2 1 2
	&chk_stack(2);
	push(@values,$values[$#values-1]);
	goto _next;

sub _swap	{
	$last = $values[$#values-1];
	$values[$#values-1] = $values[$#values];
	$values[$#values] = $last;
}

swap:			# 3 2 1 swap -> 3 1 2
	&chk_stack(2);
	&_swap;
	goto _next;

lbracket:		# immed word, goes into exec mode until ]
	$stack[$vars{'CONTEXT'}] = $stack[$vars{'CURRENT'}];
	$stack[$vars{'STATE'}] = 1;
	$stack[$vars{'MODE'}] = 0; # turn off compile
	goto _next;

rbracket:		# immed word, if was executing inside compile
			# turn compile back on
	if ($stack[$vars{'STATE'}] == 1)	{
		$stack[$vars{'STATE'}] = 0;
		$stack[$vars{'MODE'}] = 1;
		}
	goto _next;

_comp:			# error if not compiling
	goto _next if $stack[$vars{'MODE'}] == 1;
	push(@values,1);	# push flag on stack for error
	push(@values,1);	# push error number on stack for error
	goto _error;

_pairs:			# error if control structs not balanced
	&chk_stack(2);
	goto drop2 if $values[$#values] == $values[$#values-1];
	push(@values,1);
	push(@values,3);
	goto _error;

_error:			# flag errno ?error -> produces error num if true(1)
	&chk_stack(2);
	goto drop2 if !$values[$#values-1];
	print $err_msg[$values[$#values]];
	goto abort;

zequal:			# m 0= -> (true/false), true=(!0)
	&chk_stack(1);
	$values[$#values] = ($values[$#values]==0) ? 1 : 0 ;
	goto _next;

equal:			# m n = -> (true/false)
	&chk_stack(2);
	$last = $values[$#values];
	$values[$#values-1] = ($values[$#values]==$values[$#values-1]) ? 1 : 0 ;
	goto drop;

_gt:			# v1 v2 > -> t/f if v2 > v1
	&chk_stack(2);
	$values[$#values-1] = ($values[$#values] > $values[$#values-1]) ? 1 : 0;
	goto drop;

zbranch:		# m ZBRANCH -> null, if m=0,jump to foll. rel loc
	&chk_stack(1);
	if (!$values[$#values])	{
		$ip++;
		goto drop;
		}
	$ip += $stack[$ip];
	goto drop;

branch:			# BRANCH -> null, jump to following rel loc in dict
	$ip += $stack[$ip];
	goto _next;

sub scode	{
	push(@values,$ip);
	$ip = $wa;
	goto _next;
		}

sub code	{
	$wa = $stack[$stack[$ip++]];
	goto run;
		}

semicode:	# ;code immed puts addr of scode in dict, sets MODE to false;
#	push(@values,"&scode");
#	&deposit;
#	$stack[$vars{'DP'}] += 1;
#	$stack[$vars{'MODE'}] = 0;
	goto _next;

builds:			# : xx <builds yyy does> zzzz ;
	push(@values,0);
	goto variable;

_does:			# run_time behavior of does>
	$stack[$stack[$stack[$vars{'CURRENT'}]] + 3] = $ip;
	$stack[$stack[$stack[$vars{'CURRENT'}]] + 2] = "&colon";
	$stack[$vars{'MODE'}] = 0;	# set to compile mode = false
	$stack[$vars{'STATE'}] = 0;	# set STATE = false
	$stack[$vars{"DP"}] = $#stack+1;
	$last_header = $stack[$vars{'LAST'}];
	$dp_hold = $#stack;
	goto semi;

does:			# does> -> immed compiles _does into code
	# here do search for _does
	push(@values,$dict{'_does'}+2);
	&deposit;
	&pop;
	push(@values,"&scode");
	&deposit;
	goto drop;


_do:			# m n DO -> (do) -> run time for DO
	&chk_stack(2);
	push(@ret_addr,$values[$#values-1]);	# initial value
	push(@ret_addr,$values[$#values]);	# final value
	goto drop2;

_loop:			# LOOP -> (loop) -> run time for LOOP
	if (++$ret_addr[$#ret_addr] > $ret_addr[$#ret_addr-1])	{
		pop(@ret_addr);
		pop(@ret_addr);
		$ip++;
		goto _next;
		}
	goto branch;

_ploop:			# m +LOOP -> (+loop) -> run time for +LOOP
	&chk_stack(1);
	my $inc = pop(@values);
	$ret_addr[$#ret_addr] += $inc;
	if( $inc > 0 )	{
		if ($ret_addr[$#ret_addr] > $ret_addr[$#ret_addr-1])	{
			pop(@ret_addr);
			pop(@ret_addr);
			$ip++;
			goto _next;
			}
	} else	{
		if ($ret_addr[$#ret_addr] < $ret_addr[$#ret_addr-1])	{
			pop(@ret_addr);
			pop(@ret_addr);
			$ip--;
			goto _next;
			}
	}
	goto branch;

semi_s:			# terminate load
	close(INPUT);
	$_file = pop(@files);
	$byte_ptr = pop(@ptrs);
#	print "\npopped $_file from stack at $byte_ptr, stack is now [@files], ptrs is [@ptrs]\n";
	if( ! defined $_file )	{
		$stack[$vars{'LOADING'}] = 0;
		@files=();
		@ptrs=();
	} else	{
		$file = pop(@files);
		$byte_ptr = pop(@ptrs);
#		print "\npopped $file from stack at $byte_ptr, stack is now [@files], ptrs is [@ptrs]\n";
		if( $byte_ptr == 0 )	{
			$stack[$vars{'LOADING'}] = 0;
			@files=();
			@ptrs=();
			goto _next;
		}
		open(INPUT,$file);
		seek INPUT, $byte_ptr, 0;
#		print "\nOpened $file at $byte_ptr\n";
	}
	goto _next;

load:			# load file_name start_word -> loads until ;S
	$_file = &token(' ');
	if( defined $file && $_file ne $file )	{
		$byte_ptr = tell INPUT;
		push(@ptrs, $byte_ptr);
		push(@files, $file);
		push(@files, $_file);
		push(@ptrs, 0);
#		print "\npushing $_file onto stack at $byte_ptr, stack is [@files], ptrs = [@ptrs]\n";
	}
	$file = $_file;
	$start_word = &token(' ');
	$delim = ";S";
	if ( ! -e $file)	{
		print "$file not found for loading\n";
		goto abort;
	}
	$stack[$vars{'LOADING'}] = 1;
	open(INPUT,$file);
		$delim_fnd = 0;
	while(<INPUT>)	{
		if ($_ =~ "$start_word")	{
			$delim_fnd=1;
			last;
		}
	}

	if (!$delim_fnd)	{
		print "$start_word not found in $file during loading\n";
		@files=();
		goto semi_s;
	}
		goto outer;

type:			# str-addr count type -> types string at str-addr
	print $values[$#values];
	goto drop;

question:		# question -> outputs last word with ?
	print $word,"?\n";
	goto abort;

compile:		# store addr of following word in dict
	push(@values,$stack[$ip++]);
	goto _deposit;

_compile:		# force compile of immed word immediately
	$word = &token(' ');
	push(@values,$stack[$vars{'IMMED'}]);
	&search;
	&pop;
	if ($last == 0)	{
		push(@values,$stack[$stack[$vars{'CONTEXT'}]]);
		&search;
		&pop;
		}
	goto question if $last == 0;
	$values[$#values] += 2;
	goto _deposit;

qsearch:		# word ?search -> false or wa true
	&_search;
	goto _next;

sub _search
			# search CONTEXT then COMPILER
{
	push(@values,$stack[$stack[$vars{'CONTEXT'}]]);
	&search;
	return unless $values[$#values] == 0;
	return unless $stack[$vars{'MODE'}] == 1;
	push(@values,$stack[$vars{'COMPILER'}]);
	&search;
	return unless $values[$#values] == 0;
	$stack[$vars{'STATE'}] = 1;
	return;
}

sub token
{
			# bkp and line are global
	$sep = @_[0];
	$token = '';
	if ($sep eq ' ')	{ # gobble up leading blanks
		while($chars[$bptr] eq ' ')	{
			$bptr++;
			}
		}
	while ($bptr <= $#chars)	{
		last if ($chars[$bptr] eq $sep); # return if find sep char
		last if ($chars[$bptr] eq '\n');
		last if( $chars[$bptr] eq '\f');
		last if( $chars[$bptr] eq '\r');
		$token .= $chars[$bptr++];
		}
	$bptr++;
	return $token;
	}

sub count	{
 	my @str = split (//,@_[0]);
	return $#str+1;
}

_eol:		# put eol '\n' on the stack
	push(@values,"\n");
	goto _next;

_count:		# count # letters in string on stack
	&chk_stack(1);
	push(@values, &count($values[$#values]));
	goto _next;

_token:		# delim token word -> "word" bytes
	$word = &token(pop(@values));
	push(@values,$word);
	push(@values,&count($word));
	goto _next;

_concat:	# str1 str2 -> str1.str2
	&chk_stack(2);
	$values[$#values-1] .= $values[$#values];
	goto drop;

_tostr:		# n -> strn
	&chk_stack(1);
	$values[$#values] = "$values[$#values]";
	goto _next;

_indexOf:	# str1 str2 -> n, i.e. str1.indexOf(str2)
	&chk_stack(2);
	$values[$#values-1] = index($values[$#values-1], $values[$#values]);
	goto drop;

_split:		# str n -> str1 str2 ( split at index n)
	&chk_stack(2);
	if( $values[$#values] < 0 )	{
		push(@values,1);	# push flag on stack for error
		push(@values,9);	# push error number on stack for error
		goto _error;
	}
	$n = $values[$#value];
	$strlen = length($values[$#values-1]);
	$values[$#value] = substr ($values[$#values-1], $n);
	$values[$#values-1] = substr($values[$#values-1], 0, $n);
	goto _next;

_system:		# excute follwing system command
#	print "\nNot yet implemented\n";
	$word = &token('\n');
	print "\n".system($word)."\n";
	goto _next;

_perl:		# execute the perl string on the top of the stack with the next as argument replacing with the result
			# e.g. (.") sin($values[$#values-1]) " str test2 : tt test2 @ perl ;  30.0 180.0 / 3.14 * tt . -> 0.4999
	&chk_stack(2);
	$values[$#values-1] = eval $values[$#values];
	&pop;
	goto _next;

_open_in:		# str -> --,	open the file whose name is on the stack for reading
		&chk_stack(1);
		&pop;
		open(IN, "<", $last) || print "\nThe file $last cannot be opened for input! $!\n";
		$last_file_name = $last;
		goto _next;

_close:			# --, 			close the file that is open for writing
		close OUT;
		goto _next;

sub flush	{
	for( my $i=0; $i<=$#buffers; $i++)	{
		my @header = @{$buffers[$i]};
		if( $header[1] > 0 )	{
			if( $header[2] eq "" )	{
				push(@values, 1);
				push(@values, 13);
				goto _error;
			}
			open(OUT, ">", $header[2]);
			@buffer = @{$header[4]};
			print OUT @buffer;
			close OUT;
			$stack[$vars{'blk'}] = $header[0];
			&set_edited(0);
		}
	}
}

_flush:			# -- -> --, write out edited buffers, removing from buffer pool
	&flush;
	goto _next;

sub blk_exists	{
	my $value = &getHeaderNumber($stack[$vars{'blk'}]);
#	print "\n$value\n";
	if( $value == -1 )	{
		return -1;
	}
	return 0;
}

sub getHeaderNumber	{ # loop through buffer headers to find match and return array position
	local $bufno = $_[0];
	my $blkno = -1;
#	print "\n #buffers = $#buffers\n";
	for( my $i=0; $i<=$#buffers; $i++)	{
		my @header = @{$buffers[$i]};
#		print "\nstatus = '$header[0]'\t'$header[1]'\t'$header[2]'\t'$header[3]'\n";
		if( $bufno == $header[0] )	{
			$blkno = $i;
		}
	}
	return $blkno;
}

sub is_edited	{
	my $_blk = $stack[$vars{'blk'}];
	@array = @{$buffers[&getHeaderNumber($_blk)]};
	return $array[1];
}

sub set_edited	{
	my $_blk = $stack[$vars{'blk'}];
	@array = @{$buffers[&getHeaderNumber($_blk)]};
	splice(@array, 1, 1, $_[0]); # 0 for unedited, 1 for edited
	splice(@buffers, $_blk, 1, \@array);
}

sub set_filename	{
	my $_blk = $stack[$vars{'blk'}];
	@array = @{$buffers[&getHeaderNumber($_blk)]};
	splice(@array, 2, 1, $_[0]); # put filename into header
	splice(@buffers, $_blk, 1, \@array);
}

isEdited:	{
	if( &blk_exists() == -1 )
	{
		push(@values,1);	# push flag on stack for error
		push(@values,12);	# push error number on stack for error
		goto _error;
	}
	push(@values, &is_edited);
	goto _next;
}

update:	{
	if( &blk_exists() == -1 )
	{
		push(@values,1);	# push flag on stack for error
		push(@values,12);	# push error number on stack for error
		goto _error;
	}
	&set_edited(1);
	&update_time;
	goto _next;
}

sub update_time	{	# updates the time of last access, used by line and when a line is replaced.
	my $_blk = $stack[$vars{'blk'}];
	@array = @{$buffers[&getHeaderNumber($_blk)]};
	my $time = (time)[0];
	splice(@array, 3, 1, $time);
	splice(@buffers, $_blk, 1, \@array);
}

sub dump_buffer	{
			my $_blk = $stack[$vars{'blk'}];
	#		print "\nblk requested is $_blk\n";
			my @array = @{$buffers[&getHeaderNumber($_blk)]};
			print "status = '$array[0]'\t'$array[1]'\t'$array[2]'\t'$array[3]'\n";
			my @buffer = @{$array[4]};
			for( my $i=0; $i<=$#buffer; $i++)	{
				print "$i) $buffer[$i]";
				if( index($buffer[$i], "\n") < 0 )	{
					print "\n";
				}
			}
}

dumpBuffer:	{
	if( &blk_exists() == -1 )
	{
		push(@values,1);	# push flag on stack for error
		push(@values,12);	# push error number on stack for error
		goto _error;
	}
	&dump_buffer;
	goto _next;
}

sub lines	{
		my $_blk = $stack[$vars{'blk'}];
		my @array = @{$buffers[&getHeaderNumber($_blk)]};
		my @buffer = @{$array[4]};
		push(@values, $#buffer);
}

_lines:			# -- -> n, returns number of lines in current buffer;
		if( $#buffers < 0 )	{
			push(@values,1);	# push flag on stack for error
			push(@values,10);	# push error number on stack for error
			goto _error;
		}
		if( &blk_exists() == -1 )
		{
			push(@values,1);	# push flag on stack for error
			push(@values,12);	# push error number on stack for error
			goto _error;
		}
		&lines;
		goto _next;

_line:			# n -> returns line n as top of stack.  Error if out of range
	if( &blk_exists() == -1 )
		{
			push(@values,1);	# push flag on stack for error
			push(@values,12);	# push error number on stack for error
			goto _error;
		}
		&chk_stack(1);
		$_blk = $stack[$vars{'blk'}];
		@buffer = @{$buffers[&getHeaderNumber($_blk)][4]};
		if( $values[$#values] < 0 || $values[$#values] > $#buffer )	{
			push(@values,1);	# push flag on stack for error
			push(@values,9);	# push error number on stack for error
			goto _error;
		}
		$str = $buffer[$values[$#values]];
		&pop;
		&update_time;
		push(@values, $str);
		goto _next;

_erase_line:	# n -> --, erases line n in current buffer
		push(@values, "");
		&_swap;
		goto _line_store;

_line_store:	# line n -> -- stores line into current buffer at line number n, moving following down
	if( &blk_exists() == -1 )
	{
		push(@values,1);	# push flag on stack for error
		push(@values,12);	# push error number on stack for error
		goto _error;
	}
		&chk_stack(2);
		if( $values[$#values] < 0 )	{
			$values[$#values-1] = 1;
			$values[$#values] = 9;
			goto _error;
		}
		$_blk = $stack[$vars{'blk'}];
		@header = @{$buffers[&getHeaderNumber($_blk)]};
		@buffer = @{$header[4]};
		splice(@buffer, $values[$#values], 1, $values[$#values-1]);
		splice(@header, 4, 1, \@buffer);
		splice(@buffers, &getHeaderNumber($_blk), 1, \@header);
		&pop;
		&pop;
		goto update;

_blocks:		# list block status
	for( $i=0; $i<=$#buffers; $i++ )	{
		print "status[$i] = $buffers[$i][0]\t$buffers[$i][1]\t$buffers[$i][2]\t$buffers[$i][3]\n";
	}
	goto _next;

_block:			# u -> buffer u becomes current buffer
		&chk_stack(1);
		$n = $values[$#values];
		print "\nNumber requested is $n\n";
		&pop;
		if( $n < 0 || $n > $#buffers )	{
			print "\nNumber of buffers = $#buffers\n";
			push(@values,1);	# push flag on stack for error
			push(@values,9);	# push error number on stack for error
			goto _error;
		}
		$stack[$vars{'blk'}] = $n;
		goto _next;

sub new_buffer	{
	my $cnt = $_[0];
	my @tmp = ();
	for( my $i=0; $i<=$cnt; $i++)	{
		push(@tmp, "");
	}
	return \@tmp;
}

obtain:		# n -> --, create a buffer with n lines in it and set blk to the buffer number.
	&chk_stack(1);
	&create_buffer("", &new_buffer($values[$#values]));
	goto _next;

release:	# -- -> --, release the buffer in blk, set blk to -1?
	print "\nIf blk != -1, locate it in buffers or range error.\nIf edited, ask.\nIf ok, do split to remove it.";
	print "\nThen set blk == -1\n";
	push(@values,1);	# push flag on stack for error
	push(@values,4);	# push error number on stack for error
	goto _error;

_set_file:
	chk_stack(1);
	&set_filename($values[$#values]);
	&pop;
	goto _next;

fname_store:	# setFilename name -> --, stores the name into the current block header
	if( &blk_exists() == -1 )
	{
		push(@values,1);	# push flag on stack for error
		push(@values,12);	# push error number on stack for error
		goto _error;
	}
	&set_filename(&token(" "));
	goto _next;

sub create_buffer	{
	$time = (time)[0]; # ***TODO*** Add block number $nextblk to header at front and adjust all refs to header
					   # In block then search the buffers for the block # instead of using its position in the array.
					   # This is because if a buffer is replaced, i.e. removed and another added, positions change
					   # and a varible the user might have used to refer to the block would be wrong!
	push(@buffers,[$nextblk, 0, $_[0], $time, $_[1]]);	# followed by data
	$stack[$vars{'blk'}] = $nextblk++;
}

sub read	{
	my @data = <IN>;
	close IN;
	&create_buffer($last_file_name, \@data);
}

_read:			# -- -> lines, array, 		read the file into a buffer as an array of lines, put buffer # on stack
				# More thought here.  How to get the n-th buffer and handle the lines in that buffer?
				# Do we need a buffer header that keeps edit status and file name?  flush writes out edited files?
				# When using a buffer, extract from array and push to end, making current buffer always $#buffers
		&read;
		goto _next;

fopen:	# fopen filename opens the file for input, reads it in then closes it
	push(@values, &token(" "));
	&pop;
	open(IN, "<", $last) || print "\nThe file $last cannot be opened for input! $!\n";
	$last_file_name = $last;
	goto _read;

_write:			# write item on stack to current block
	&chk_stack(1);
#	print OUT $values[$#values];
	$item = $values[$#values];
	$_blk = $stack[$vars{'blk'}];
	$_hn = &getHeaderNumber($_blk);
	@buffer = @{$buffers[$_hn][4]};
	$str = "";
	$n = $#buffer;
	if( $#buffer > 0 ) {
		$str = $buffer[$n];
		if( index($str, "\n") > 0 )	{
			$str = substr($str, 0, index($str, "\n"));
			if( length($str) > 0 )	{
				$str = "";
				$n++;
			}
		}
	}
	$values[$#values] = $str.$item;
	push( @values, $n);
	goto _line_store;

outer:		# outer interpreter
	goto _outer;

_outer:
		print "Outer Interpreter Starting\n" if (!$first);
		$first = 1;
		if(!$stack[$vars{'LOADING'}])	{
			print "> ";
			$line = <STDIN>;
			}	else	{
				$line = <INPUT>;
			}
		chop($line);
		if( length($line) == 0 )	{
			goto _outer;
		}
		@chars = split(//,$line);
		push(@chars,' ');
			if( $stack[$vars{'LOADING'}])	{
#				pop(@chars); # attempt to remove extra character at end
				}
		$bptr = 0;
_exec:
		while($bptr <= $#chars)	{
			$word = &token(' ');
			$word =~ s/^\s+//; #remove leading spaces
			$word =~ s/\s+$//; #remove trailing spaces

			last if ( length($word) == 0 );
#		print "\n word is |$word|\n";
			$name = $word;
			$stack[$vars{'STATE'}] = 0;	# set STATE = false
			$comp = $stack[$vars{'MODE'}];
			$tst_wa = $dict{&vocab($name)};
			if( $searching ) {
#				$tst_value = &vocab($name);
#				print "\n$tst_value\t$wa\t$dict{&vocab($name)}";
				&_search();
				if( pop(@values) == 1 ) {
					$tst_wa = pop(@values);
				} else	{
					$tst_wa = '';
				}
			}
			if ($tst_wa eq '')	{
#			&_search;
#			if (pop(@values) == 0)	{
				if ($word =~ /^[-|+]?\d+\.?\d*|[-|+]?\.\d+$/)	{
					if (!$comp)	{
						push(@values,$word);
						$loc=9; write if $tracing;
						goto _exec;
					}	else	{
							push(@stack,$addr_lit);
							push(@stack,$word);
							$stack[$vars{'DP'}]+=2;
							$loc=10; write if $tracing;
							goto _exec;
						}
				}
				$loc=101; write if $tracing;
				#print "\n$line\n";
				my $msg = "";
				if(!$stack[$vars{'LOADING'}])	{
					$msg = " in $_file";
				}
				print "'$word' not found at $bptr in '$line'",$msg;
				print "\n";
				goto abort;
			}
			$wa = $tst_wa + 2;
#			$wa = pop(@values)+2;
			$immed = ($immed_flag{$name} == 1)? 1 : 0;
			$state = $stack[$vars{'STATE'}];
		if ((($immed == 1) && $comp) || ($comp == 0))	{
#				push(@ret_addr,$wa);
				# do search for execute
				$ip = $dict{&vocab("execute")} + 2;
				$immed=0;
				goto run;
			}	else	 {
					push(@stack,$wa);
					$stack[$vars{'DP'}]++;
					$loc=11; write if $tracing;
				}
		}

		goto outer;

sub prt_list	{
	print join(',',@_),"\n";
	while (@_)	{
		local($a) = shift(@_);
		print $a,"=",unpack('b*',$a),", ";
	}
	print "\n";
}

###################   Graphics implementation ####################
plot:
	&_gnuplot();
	goto _next;

sub _gnuplot	{
	# In the graphics package, plot will provide taking the data from x and y as above
	# and writing it to the $data_file, then calling _plot function.
	#
#	These come from the variables via $xlabel =  $stack[$vars{'x_label'}]; strings?
	$xlabel = $stack[$vars{'x-label'}];
	$ylabel = $stack[$vars{'y-label'}];
	$title = $stack[$vars{'plt-title'}];
	$xlabel_font = $stack[$vars{'xlabel_font'}];
	$ylabel_font = $stack[$vars{'ylabel_font'}];
	$title_font = $stack[$vars{'title_font'}];
	$xsize = $stack[$vars{'xsize'}];
	$ysize = $stack[$vars{'ysize'}];
	$plt_str = $stack[$vars{'plt_str'}];
	$scaling = $stack[$vars{'scaling'}];
	$xtics = $stack[$vars{'xtics'}];
	$grid = $stack[$vars{'grid'}];
	$key = $stack[$vars{'key'}];
	$data_file = $stack[$vars{'data_file'}];
#
	open (GNUPLOT, "|gnuplot");
	print GNUPLOT <<EOPLOT;
	reset
	set term post color "Courier" 12
	set output "$data_file.ps"
	set size $xsize ,$ysize
	$key
	$scaling
	set xlabel "$xlabel" font "xlabel_font"
	set ylabel "$ylabel" font "$ylabel_font"
	set title "$title" font "$title_font"
	$grid
	set xtics $xtics
	plot $plt_str
EOPLOT

	close(GNUPLOT);
	system ("open","$data_file.ps");
}

open_gnuplot:
    &_open_gnuplot();
    goto _next;

sub _open_gnuplot {
	open (GNUPLOT, "|gnuplot");
}

plotit:
    &_plotit();
    goto _next;

sub _plotit {
    close(GNUPLOT);
 #   system ("open", "$data_file.ps");
}

gnuplot_command:
    &_gnuplot_command();
    goto drop;

sub _gnuplot_command {
    print GNUPLOT "$values[$#values]\n";
}
#################### End of graphics implementation ##################

format top =
		Tracing Execution
  LOC   IP   WA     RET# (RET1,RET2,RET3)   VAL#  (VAL1,VAL2,VAL3)   IMMED  COMP  word     executing
____________________________________________________________________________________________________
.
format STDOUT =
@### @#### @#### @#### (@####,@####,@####) @#### (@####,@####,@###) @#### @#### @>>>>>>>> @>>>>>>>>>
$loc, $ip, $wa, $#ret_addr, $ret_addr[$#ret_addr], $ret_addr[$#ret_addr-1], $ret_addr[$#ret_addr-2], $#values, $values[$#values], $values[$#values-1], $values[$#values-2], $immed, $comp, $word, $stack[$wa-2]
.
