
# Setting up the development environment

## Git setup

We're not going to use git, so we need to configure it:

	git config --global user.name "Firstname Lastname"
	git config --global user.email "you@example.com"

For me this would be:

	git config --global user.name "Christoph Hellwig"
	git config --global user.email "hch@lst.de"

(But please use your own name, not mine :))

With this the git commits will shop with your name and email address.

Linux also requires the developers certificate of origin that guarantees
your rights, which requires a signoff.  To do the signoff it is helpful
to create a file that contains it that you can copy and pase or just
include from the browser.

I have a file name "so" with the contents of just this line:

Signed-off-by: Christoph Hellwig <hch@lst.de>

And then in vim do the ":r so" to include it.

We're going to add the signoff for our commits here, but before you
submit anything to a public Linux tree please actually read it first
before you accept it!  It is available in the Linux source tree we've
just clone in Documentation/process/submitting-patches.rst or only
here:

	https://www.kernel.org/doc/Documentation/process/submitting-patches.rst

Git commits will always fire off an editor to write the commit message.
The default for Debian is nano, which I don't particularly like.  You
can switch this by adding this to the .bashrc file in your home
directory (replace vim with your choice of editor):

	export EDITOR=vim

then re-read the .bashrc file

	. ~/.bashrc

apt-get install indent

## Email setup

Linux patches are emailed to mailing lists.  We'll use the lkw@jrsl.org
to send emails to, and this assumes you use your university account for
sending email.  If you don't have a university account talk to me and we'll
figure out what to do instead.

For the University account go to:

Google Account -> Security -> Signing in to Google -> *2-Step Verification*:
App passwords

and create an application specific password and note it.

The in the VM do:

	git config --global sendemail.confirm auto
	git config --global sendemail.smtpServer "smtp.gmail.com"
	git config --global sendemail.smtpServerPort 587
	git config --global sendemail.smtpEncryption tls
	git config --global sendemail.smtpUser = <your university email address>
	git config --global sendemail.smtpPass = <the password generated above>

**Note**: the password is stored unencrypted in the ~/.gitconfig file.
Don't share the VM with anyone as that means whoever sees it can send email
in your name!

And then try sending a simple mail by creating a file like this:

echo "Subject: test" > foo.txt

and then sending it:

git-send-email --to lkw@jrsl.org ./foo.txt

And with that we're ready to do some kernel development!
