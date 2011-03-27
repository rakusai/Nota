#-----------------------------------------------------------#
#Programmmed by Isshu Rakusai
#Created: 2007/02/26
#URLを元にHTTP経由でデータを取得するためのパッケージ
#-----------------------------------------------------------#

package NOTA::SimpleHttp;

use utf8;
binmode STDIN,  ":bytes"; 
binmode STDOUT, ":encoding(utf-8)"; 

use strict;
use warnings;


# @(#)http.pl Copyright (C)2001 ASH. http://ash.jp/
#
# 簡易ブラウジングスクリプト（HTTP）
#   Usage: http.pl URL（http://host:port/dir/file）

use Socket;
use FileHandle;

#-----------------------------------------------------------#
#--  コンストラクタ ----------------------------------------#
sub new
{
	my $class = shift;
	my $self  = {};
	$self->{url}   = "";
	$self->{body}   = "";
	$self->{filename}   = "";
	bless ($self, $class);
}

#-----------------------------------------------------------#
#--  取得系関数 --------------------------------------------#
sub get_body
{
	my $self = shift;
	return $self->{body};
}
sub get_filename
{
	my $self = shift;
	my $defaultname = shift;
	
	$self->{url} =~ /([^\/\\]*?)(\?.*)?$/;
	$self->{filename} = $1;
	if (!$self->{filename}) {
		#もし空なら、デフォルトを代入
		$self->{filename} = $defaultname;
	}
	return $self->{filename};
}

#-----------------------------------------------------------#
#--  HTTPデータ取得 ----------------------------------------#
sub request
{
	my $self = shift;
	$self->{url} = shift;
	my ($proxy_host, $proxy_port, $http);
	my ($con_host, $con_port);
	my ($host, $port, $url, $path, $ip, $sockaddr);
	my ($buf,$isbody);

	# HTTPプロトコルのバージョン
	$http = '1.1';

	# プロキシサーバの設定
	#$proxy_host = 'XXX.XXX.XXX.XXX';
	#$proxy_port = 8080;

	# デフォルトホストの設定
	$host = 'localhost';
	$port = getservbyname('http', 'tcp');
	$path = '/';

	# URL解析処理
	$self->{url} =~ m!(http:)?(//)?([^:/]*)?(:([0-9]+)?)?(/.*)?!;
	if ($3) {$host = $3;}
	if ($5) {$port = $5;}
	if ($6) {$path = $6;}

	if ($proxy_host) {
		# プロキシサーバ経由
		$con_host = $proxy_host;
		$con_port = $proxy_port;
		$url = $self->{url};
	} else {
		$con_host = $host;
		$con_port = $port;
		$url = $path;
	}

	# ソケットの生成
	$ip = inet_aton($con_host) || die "host($con_host) not found.\n";
	$sockaddr = pack_sockaddr_in($con_port, $ip);
	socket(SOCKET, PF_INET, SOCK_STREAM, 0) || die "socket error.\n";

	# ソケットの接続
	connect(SOCKET, $sockaddr) || die "connect $con_host $con_port error.\n";
	autoflush SOCKET (1);

	# HTTP要求を送信
	if ($http eq '1.1') {
		print SOCKET "GET $url HTTP/1.1\n";
		print SOCKET "Host: $host\n";
		print SOCKET "Connection: close\n\n";
	} else {
		print SOCKET "GET $url HTTP/1.0\n\n";
	}

	# HTTP応答を受信
	$self->{body} = "";
	
	$isbody = 0;
	while ($buf=<SOCKET>) {
		if ($isbody){
			$self->{body} .= $buf;
		}
		if ($buf =~ /^[\r\n]+$/){
			$isbody = 1;
		}
	}
	
	# 終了処理
	close(SOCKET);
}

#-----------------------------------------------------------#
#END_OF_SCRIPT
1;