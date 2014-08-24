#!/bin/bash
TEST_FILE=test.file
#如果使用了FIELDWIDTHS就会覆盖FS
awk -n  -F ":"  -b -df.x -v end='_' 'BEGIN{OFS="*";ORS="+";OFMT="%.2g";FIELDWIDTHS=3;print "Hello World!";print 3.1334}{print "FPAT="FPAT,"FILENAME="FILENAME,"FNR="FNR,NF,$(1)end}END{print "Goodbye Wold"}' ${TEST_FILE} > /tmp/1

awk 'BEGIN{print PROCINFO["egid"],PROCINFO["pid"],PROCINFO["sorted_in"]}'
awk 'BEGIN{a[1]="hey";a[2]="there";for(i in a) print a[i];}'
awk '
	function print_hellO(name){
		print "Hello "name;
	}
	/c1/{
		if(FNR==1) {
			print "total="NF" line:"FNR"="$0;
		}else {
			thf_func="print_hellO";
			@thf_func("Jame");
			print_hellO("Ian");
		}
	}' ${TEST_FILE}
awk 'BEGIN{FS=":"}{print $1|"sort"}' /etc/passwd
awk 'BEGIN{count=0;}{count++;}END{print count;}' /etc/passwd
awk '{print NR":"$0"\n"}' /etc/passwd

#空格是awk中的字符串连接符，如果system中需要使用awk中的变量可以使用空格分隔，或者说除了awk的变量外其他一律用""引用起来
awk '/root/{system("echo  " $0)}' /etc/passwd

#设置纪录之间的分隔符
awk 'BEGIN{ORS="_\n";FS=":"}{print NR,$1,$NF}' /etc/passwd

#FILENAME不能在BEGIN中使用，因为那时还未能获得任何与文件操作相关的纪录
awk '
	BEGIN{
			print "ARGC="ARGC;
			for (var in ARGV){
					print ARGV[var];
			}
	}
	{

		print "FILENAME:"FILENAME
	}
' /etc/passwd

awk '
	BEGIN{
			OFMT="%.3f";
			print 2/3,1.23423423;
			print "HOME:",ENVIRON["HOME"];
	}'

#FIELDWIDTHS用于指定的宽度用于输入，忽略FS
echo 2012333221 | awk 'BEGIN{ FIELDWIDTHS="4 3 2 2 2"}{print $1"-"$2"-"$2;}'


#RSTART和RLENGTH和match函数一起使用，用于指示匹配的起始和长度值
awk 'BEGIN{match("this is a test", /^[a-z ]+$/); print RSTART,RLENGTH}'

awk 'BEGIN{total=0}
	{
		if ($1~/^[0-9]+\.?[0-9]*/){
				total += $1;
		 }
	}
	END{print total;}
	' data.txt

awk -v start=10 -v lines=10 '{if (NR >= start && NR <=start+lines)print NR,":",$0;}' /etc/passwd

#NR:已经读出的的记录数 FNR:当前文件的记录数
#下面的例子是区别两个文件的
awk 'NR==FNR{print FILENAME,FNR;} NR>FNR{print FILENAME,FNR}' $HOME/.vimrc $HOME/.bashrc

#上面的例子也可以用ARGIND变量来差别
awk '{if(ARGIND == 1){print "handling file1";} else if(ARGIND==2){print "handling file2";}}' $HOME/.vimrc $HOME/.bashrc

#打印指定的行区域(10,16)
awk 'NR==10,NR==16{print}' $HOME/.vimrc

#使用RS变量指定记录间的分隔符
awk 'BEGIN{RS=":"}{print}' ${TEST_FILE}

#指定了FS和RS
awk '
	BEGIN{
			FS=":";
			RS="\n";
	}
	{
			print NF;
	}' ${TEST_FILE}


awk '{v[$1]++;}END{for (i in v){ print i,":",v[i]; }}' alphas.txt|sort

#可以使用-v和'$VAR'的形式往awk传变量
awk -v home=$HOME 'BEGIN{print '$UID',home}'

#date命令从管道输出到getline，赋值给d。需要显式关闭date管道，用的命令与打开时完全相同才行
awk 'BEGIN{"date"|getline d; close("date");print d}'
#getline一直读取，直到返回0
awk 'BEGIN{while(getline < "./alphas.txt" > 0){print $0}}'

#重定向
awk '/[0-9]+\.?[0-9]*$/{if($1 > 20){print >> "/tmp/2"}}' data.txt


