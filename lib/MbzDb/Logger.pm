#!/usr/bin/perl -w

package MbzDb::Logger;

use strict;
use warnings;
use POSIX;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(Get);

use constant {
    DEBUG      => 1,
    INFO       => 10,
    WARNING    => 25,
    USER_ERROR => 50,
    ERROR      => 75,
    FATAL      => 99
};

# new()
# Create a new logger instance.
sub new {
    my $class = shift;
    my $self = {
    };
    return bless $self, $class;
}

sub GetSeverityWord {
    my $severity = shift;
    
    if($severity <= DEBUG) {
        return "DEBUG";
    }
    if($severity <= INFO) {
        return "INFO";
    }
    if($severity <= WARNING) {
        return "WARNING";
    }
    if($severity <= USER_ERROR) {
        return "USER_ERROR";
    }
    if($severity <= ERROR) {
        return "ERROR";
    }
    if($severity <= FATAL) {
        return "FATAL";
    }
}

sub log {
    my ($self, $severity, $message) = @_;
    my $ts = strftime("%F %T", localtime($^T));
    print "$ts [" . MbzDb::Logger::GetSeverityWord($severity) . "] $message\n";
}

sub logDebug {
    my ($self, $message) = @_;
    return $self->log(DEBUG, $message);
}

sub logInfo {
    my ($self, $message) = @_;
    return $self->log(INFO, $message);
}

sub logWarning {
    my ($self, $message) = @_;
    return $self->log(WARNING, $message);
}

sub logUserError {
    my ($self, $message) = @_;
    return $self->log(USER_ERROR, $message);
}

sub logError {
    my ($self, $message) = @_;
    return $self->log(ERROR, $message);
}

sub logFatal {
    my ($self, $message) = @_;
    $self->log(FATAL, $message);
    exit(1);
}

# Get()
# Get the active logger.
sub Get {
    return new MbzDb::Logger();
}

1;
