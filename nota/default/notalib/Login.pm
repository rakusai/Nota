#-----------------------------------------------------------#
#Programmmed by Isshu Rakusai
#CreateDate: 2007/02/25
#LastUpdate: 2007/02/25
#-----------------------------------------------------------#

package NOTA::Login;

use utf8;
use Digest::MD5 qw(md5 md5_hex md5_base64);

binmode STDIN,  ":bytes"; 
binmode STDOUT, ":encoding(utf-8)"; 

use strict;
use warnings;


#-----------------------------------------------------------#
#--  コンストラクタ ----------------------------------------#
sub new
{
	my $class = shift;
	my $self  = {};
	$self->{user}   = "none";
	$self->{hash}   = "";
	$self->{power}   = "";
	$self->{remember}  = 0;
	$self->{anonymous}  = "view";
	$self->{editmode}  = "false";
	$self->{certify}  = "noskip"; 
	#ログイン処理のオプションを読み込む
	if (defined($main::m_certify)){
		$self->{certify}  = $main::m_certify;
	}
	
	bless ($self, $class);
}

#-----------------------------------------------------------#
#--  取得系関数 --------------------------------------------#
sub get_user
{
	my $self = shift;
	return $self->{user};
}
sub get_power
{
	my $self = shift;
	return $self->{power};
}
sub get_remember
{
	my $self = shift;
	return $self->{remember};
}
sub get_anonymous
{
	my $self = shift;
	return $self->{anonymous};
}
sub get_editmode
{
	my $self = shift;
	return $self->{editmode};
}
sub get_certify
{
	my $self = shift;
	return $self->{certify};
}
sub is_access_forbidden
{
	my $self = shift;
	return (($self->{power} eq "" || $self->{editmode} ne "true") && $self->{anonymous} eq 'none');

}

#-----------------------------------------------------------#
#--  md5のhashkeyを作成 ------------------------------------#
sub gethashkey
{
	my ($self, $user, $pass) = @_;
	return md5_hex($user ." ". $pass);
}


#-----------------------------------------------------------#
#--  ログインする ------------------------------------------#
sub dologin
{
	my ($self, $user, $pass, $remember) = @_;

	#代入
	$self->{user}     = $user;
	$self->{hash}     = $self->gethashkey($user,$pass);
	
	#完全にスルーするとき
	if ($self->{certify} eq "skip"){
		return 1;
	}
	
	#認証する
	my $res = $self->accountcheck($main::m_memberpath);
	if ($res == 0){
		#認証失敗
		$self->{user}  = "none";
		$self->{hash}  = "";
		$self->{power} = "";
		$self->{editmode} = "false";
		return 0;
	}
	
	#クッキーに書き出し
	my $expires = '';
	if ($remember eq "true"){
		#IDとパスワードを記憶する(30日間)
		$expires = " expires=" . main::nota_get_gmt(time + 30 * 24 * 60 * 60) . ";";
	}
	print "Set-Cookie: user_id=" . $self->{user} . ";$expires\n";
	print "Set-Cookie: hash_key=" . $self->{hash} . ";$expires\n";
	print "Set-Cookie: editmode=true;$expires\n";
	
	return 1;
}

#-----------------------------------------------------------#
#----- 現在のログイン状態を取得する ------------------------#
sub getlogin
{
	my $self = shift;
	my $cookie = shift;
	
	#For Debug Only
	#	$self->{user}     = "taro";
	#	$self->{editmode} = "true";
	#	$self->{power}    = "admin";
	#	return 1;
	
	#ユーザー名の取得
	#クッキーから取得する場合
	#もし、他のシステムと連携するときは、ここを変更する
	$self->{user}     = $$cookie{'user_id'};
	$self->{hash}     = $$cookie{'hash_key'};
	$self->{editmode} = $$cookie{'editmode'};
	
	#バリデーション
	main::nota_validate($self->{user});
	main::nota_validate($self->{hash});
	
	#認証する
	my $res = $self->accountcheck($main::m_memberpath);
	if (!$res){
		#認証失敗
		$self->{user}  = "none";
		$self->{hash}  = "";
		$self->{power} = "";
		$self->{editmode} = "false";
	}
	
	#ログイン処理を外部で行う
	if ($self->{certify} eq "skip"){
		$self->{editmode} = "true"; #編集モードは常にtrue
	}
	
	return $self->{power};
}


#-----------------------------------------------------------#
#----- 編集権限を持つか、ユーザー認証する ------------------#
sub accountcheck
{
	my $self = shift;
	my $memfile = shift;
	
	if (!defined($self->{user}) || !defined($self->{hash})){
		$self->{power} = '';
		return 0;
	}
	
	my @lines = (); #メンバーリスト
	if (open(DATA,"< $memfile")) { 
		@lines = <DATA>;
		close(DATA);
		if (defined($main::m_master_passwd) && $main::m_master_passwd ne ''){
			#マスターパスワード
			push(@lines,"0,admin," . $main::m_master_passwd . ",admin,\n");
		}
		foreach (@lines){
			#データを見る
			my ($del,$user,$pass,$power,$etc) = split(/,/,$_);
			if ($self->{user} eq $user && $del ne '1'){
				if ($self->gethashkey($user,$pass) eq $self->{hash}){
					$self->{power} = $power;
				}
			}
			if ($user eq "anonymous" && $del ne '1'){
				#データを代入
				$self->{anonymous} = $power;
			}
		}
	}
	
	#結果を返す
	if (!($self->{power} =~ /(admin|member|guest)/)){
		$self->{power} = '';
		return 0;
	}
	
	return 1;
}


#-----------------------------------------------------------#
#END_OF_SCRIPT
1;