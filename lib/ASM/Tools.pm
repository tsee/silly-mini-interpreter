package ASM::Tools;
use 5.14.2;
use warnings;
use Carp ();

use ASM qw(uint32);

use Exporter qw(import);

our @EXPORT_OK = qw(
    loop_down
    loop_rel_up
    loop_counter
    loop_target
    loop_cmp
);
our %EXPORT_TAGS = (all => \@EXPORT_OK);

our $LoopCounterMemorySlot;
our $LoopTargetMemorySlot;
our $LoopCmpMemorySlot;

=head2 loop_down

Emits asm for a simply countdown loop with a jumpz to test for end.

Starts a loop block.

Must contain a C<loop_counter> verb.

=cut

sub loop_down (&) {
    my ($obj, @data) = &ASM::intuit_params;
    local $LoopCounterMemorySlot;

    my $loop_start = $obj->position;

    $data[0]->();

    if (not defined $LoopCounterMemorySlot) {
        Carp::croak("You need to set the 'loop_counter' for the loop");
    }

    $obj->emit_subconst($LoopCounterMemorySlot, 1);

    my $backpatch_pos = $obj->position+1;
    $obj->emit_jumpz(0xdeadbeef, $LoopCounterMemorySlot);
    $obj->emit_jump($loop_start);

    my $done_pos = $obj->position;
    $obj->backpatch($backpatch_pos, uint32($done_pos));

    return;
}

sub loop_rel_up (&) {
    my ($obj, @data) = &ASM::intuit_params;
    local $LoopCounterMemorySlot;
    local $LoopTargetMemorySlot;
    local $LoopCmpMemorySlot;

    my $counter_backpatch_pos = $obj->position+1;
    $obj->emit_movconst(0xdeadbeef, 0);

    my $loop_start = $obj->position;
    $data[0]->();

    if (not defined $LoopCounterMemorySlot) {
        Carp::croak("You need to set the 'loop_counter' for the loop");
    }
    if (not defined $LoopTargetMemorySlot) {
        Carp::croak("You need to set the 'loop_target' for the loop");
    }
    if (not defined $LoopCmpMemorySlot) {
        Carp::croak("You need to set the 'loop_cmp' for the loop");
    }

    $obj->emit_addconst($LoopCounterMemorySlot, 1);

    $obj->emit_eqrel($LoopCmpMemorySlot, $LoopCounterMemorySlot, $LoopTargetMemorySlot);
    my $backpatch_pos = $obj->position+1;
    $obj->emit_jumpnz(0xdeadbeef, $LoopCmpMemorySlot);
    $obj->emit_jump($loop_start);

    $obj->backpatch($counter_backpatch_pos, uint32($LoopCounterMemorySlot));
    my $done_pos = $obj->position;
    $obj->backpatch($backpatch_pos, uint32($done_pos));

    return;
}

=head2 loop_counter

Verb for use in C<loop* {}> blocks.

=cut

sub loop_counter ($) {
    my ($obj, @data) = &ASM::intuit_params;

    if (defined $LoopCounterMemorySlot) {
        Carp::croak("Cannot set 'loop_counter' twice for the same loop!");
    }

    $LoopCounterMemorySlot = $data[0];
}

=head2 loop_target

Verb for use in C<loop* {}> blocks.

=cut

sub loop_target ($) {
    my ($obj, @data) = &ASM::intuit_params;

    if (defined $LoopTargetMemorySlot) {
        Carp::croak("Cannot set 'loop_target' twice for the same loop!");
    }

    $LoopTargetMemorySlot = $data[0];
}

=head2 loop_cmp

Verb for use in C<loop* {}> blocks.

=cut

sub loop_cmp ($) {
    my ($obj, @data) = &ASM::intuit_params;

    if (defined $LoopCmpMemorySlot) {
        Carp::croak("Cannot set 'loop_cmp' twice for the same loop!");
    }

    $LoopCmpMemorySlot = $data[0];
}

1;
