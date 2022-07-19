<h1>Установка Agoric</h1>
<p>
    Для начала придумываем имя ноды и записываем его в переменную  (nodename заменить на свое произвольное значение):
</p>
<pre>
    <code>
        AGORIC_NODENAME=nodename
        echo 'export AGORIC_NODENAME='$AGORIC_NODENAME >> $HOME/.bash_profile
        source $HOME/.bash_profile
    </code>
</pre>

<p>Устанавливаем NodeJS:</p>
<pre>
    <code>
        curl https://deb.nodesource.com/setup_14.x | sudo bash
        curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
        echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list
        sudo apt upgrade -y < "/dev/null"
        sudo apt install nodejs=14.* yarn build-essential jq git -y < "/dev/null"
    </code>
</pre>

<p>Устанавливаем Go</p>
<pre>
    <code>
        wget -O go1.17.1.linux-amd64.tar.gz https://golang.org/dl/go1.17.linux-amd64.tar.gz
        rm -rf /usr/local/go && tar -C /usr/local -xzf go1.17.1.linux-amd64.tar.gz && rm go1.17.1.linux-amd64.tar.gz
        cat <<'EOF' >> $HOME/.bash_profile
        export GOROOT=/usr/local/go
        export GOPATH=$HOME/go
        export GO111MODULE=on
        export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin
        EOF
        . $HOME/.bash_profile
        cp /usr/local/go/bin/go /usr/bin
        go version
    </code>
</pre>