define-command delete-surround %!
	_surrounding-object-info 'delete surround'
	on-key %@ %sh^
		case $kak_key in
		b|'('|')'|B|'{'|'}'|r|'['|']'|a|'<lt>'|'<gt>'|'"'|Q|"'"|q|'`'|g)
			#use $val{key}. if use $kak_key, it break quote case
			echo '_select-surrounding-pair %val{key}'
			echo 'execute-keys d<space>' ;;
		t) echo delete-surrounding-tag ;;
		#to close information window, use execute-keys
		*) echo 'execute-keys :nop<ret>' ;;
		esac
	^@
!

define-command -hidden -params 2 _change-surround %{ execute-keys "r%arg{1}<space>r%arg{2}<space>;" } 
define-command change-surround %!
	_surrounding-object-info 'change-surround'
	on-key %@ %sh^
		case $kak_key in
		b|'('|')'|B|'{'|'}'|r|'['|']'|a|'<lt>'|'<gt>'|'"'|Q|"'"|q|'`'|g)
			#use $val{key}. if use $kak_key, it break quote case
			echo '_select-surrounding-pair %val{key}'
			echo '_change-surround-info'
			#use $val{key}. if use $kak_key, it break quote case
			echo 'on-key %{ _impl-surround _change-surround %val{key} }' ;;
		t) echo change-surrounding-tag ;;
		#to close information window, use execute-keys
		*) echo 'execute-keys :nop<ret>' ;;
		esac
	^@
!

define-command -hidden -params 2 _surround %{ execute-keys "i%arg{1}<esc>a%arg{2}<esc>" }
define-command surround %{
	info -title 'surround' 'enter char to select surrounder
(),[],{},<>: surround with the pair
t:           surround with markup tag
others:      surround with the character
'
	on-key %{ %sh{
		if [ $kak_key = t ] ; then
			echo surround-with-tag
		else
			#use $val{key}. if use $kak_key, it break quote case
			echo '_impl-surround _surround %val{key}'
		fi
	}}
}

define-command -hidden -params 1 _select-surrounding-pair %{ execute-keys "<a-a>%arg{1}<a-S>" }
define-command -hidden -params 2 _impl-surround %! %sh@
	command=$1
	case $2 in
	'('|')') open='('; close=')' ;;
	'['|']') open='['; close=']' ;;
	'{'|'}') open='{'; close='}' ;;
	'<lt>'|'<gt>') open='<lt>'; close='>' ;;
	\')  open="<'>"; close="<'>" ;;
	\") open='<">'; close='<">' ;;
	*) open=$2; close=$2 ;;
	esac
	echo "$command $open $close"
@!

define-command -hidden -params 1 _surrounding-object-info %{
	info -title %arg{1} 'select surrounding object
b,(,): paranthes block
B,{,}: braces block
r,[,]: bracket block
a,<,>: angle block
",Q:   double quote string
\',q:   single quote string
`,g:   grove quote string
t:     markup tag
'
}

define-command -hidden _change-surround-info %{
	info -title 'change surround' 'enter char to select surrounder
(),[],{},<>: surround with the pair
others:      surround with the charactr
'
}

#use evaluate-commands to collapse undo history
define-command surround-with-tag %{ evaluate-commands %{
	#first append, to put cursor inside inserting tag pair
	execute-keys 'a<lt>/><esc>i<lt>><esc>'
	execute-keys '<a-a>c<lt>>,<lt>/><ret>'
	execute-keys '<a-S><a-a>>s><ret>)'
	_activate-hooks-tag-attribute-handler
	execute-keys i
}}

define-command delete-surrounding-tag %{
	_select-surrounding-tag
	execute-keys d<space>
}

define-command change-surrounding-tag %{
	_select-surrounding-tag
	execute-keys '<a-i>c<lt>/?,><ret>)'
	_activate-hooks-tag-attribute-handler
	execute-keys c
}

define-command -hidden _activate-hooks-tag-attribute-handler %{
	hook -group surround-tag-attribute-handler window InsertKey <space> %{
		execute-keys '<backspace><a-;><space><space>'
		remove-hooks window surround-tag-attribute-handler
	}
	hook -group surround-tag-attribute-handler window ModeChange insert:normal %{
		remove-hooks window surround-tag-attribute-handler
	}
}

define-command _select-surrounding-tag %{
	execute-keys ';Ge<a-;>'
	%sh{
		tag_list=`echo "$kak_selection" | grep -P -o '(?<=<)[^>]+(?=>)'`
		open=
		open_stack=
		close=
		for tag in $tag_list ; do
			if [ `echo $tag | cut -c 1` != / ] ; then
				case $tag in
				#self-closing tags
				area|base|br|col|command|embed|hr|img|input|keygen|link|meta|param|source|track|wbr) continue ;;
				*)
					open=$tag
					open_stack=$open\\n$open_stack ;;
				esac
			else
				if [ $tag = /$open ] ; then
					open_stack=${open_stack#*\\n}
					open=`echo $open_stack | head -n 1`
				else
					close=${tag#/}
					break
				fi
			fi
		done
		echo "execute-keys '<a-a>c<lt>$close>,<lt>/$close><ret>'"
		echo "execute-keys '<a-S><a-a>>'"
	}
}
