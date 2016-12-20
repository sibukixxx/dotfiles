# title bar 変更
function title()
{
    echo -n "\e]2;$1\a"
}

function datetime()
{
    date +'%Y%m%d_%H%M%S'
}

