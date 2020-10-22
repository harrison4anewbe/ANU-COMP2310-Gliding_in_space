-- Suggestions for packages which might be useful:

with Ada.Real_Time;              use Ada.Real_Time;
with Ada.Text_IO;                use Ada.Text_IO;
with Exceptions;                 use Exceptions;
with Rotations;                  use Rotations;
with Vectors_3D;                 use Vectors_3D;
with Vehicle_Interface;          use Vehicle_Interface;
with Swarm_Structures;           use Swarm_Structures;
with Ada.Numerics;

package body Vehicle_Task_Type is

   task body Vehicle_Task is

      Vehicle_No : Positive; pragma Unreferenced (Vehicle_No);
      -- You will want to take the pragma out, once you use the "Vehicle_No"
      message_get : Inter_Vehicle_Messages;
      latest_message : Inter_Vehicle_Messages;

   begin

      -- You need to react to this call and provide your task_id.
      -- You can e.g. employ the assigned vehicle number (Vehicle_No)
      -- in communications with other vehicles.

      accept Identify (Set_Vehicle_No : Positive; Local_Task_Id : out Task_Id) do
         Vehicle_No     := Set_Vehicle_No;
         Local_Task_Id  := Current_Task;
      end Identify;

      -- message_initialize (latest_message);

      -- Replace the rest of this task with your own code.
      -- Maybe synchronizing on an external event clock like "Wait_For_Next_Physics_Update",
      -- yet you can synchronize on e.g. the real-time clock as well.

      -- Without control this vehicle will go for its natural swarming instinct.

      select

         Flight_Termination.Stop;

      then abort

         Outer_task_loop : loop

            Wait_For_Next_Physics_Update;

            -- Your vehicle should respond to the world here: sense, listen, talk, act?

            -- find globe around
            -- Put_Line (Current_Charge'Image);
            declare
               globes_around : constant Energy_Globes := Energy_Globes_Around;
               time_now : constant Ada.Real_Time.Time := Ada.Real_Time.Clock;
            begin
               -- find globe and send message
               if globes_around'Length > 0 then
                  message_get.globe_num := globes_around'Length;

                  for index in globes_around'Range loop
                     message_get.globes_get (index) := globes_around (index);
                  end loop;
                  --.globes_get := globes_around;

                  message_get.comm_time := Ada.Real_Time.Clock;
                  message_get.my_energy := Current_Charge;
                  latest_message := message_get;
                  move_to_destination (latest_message, Position, Velocity, Acceleration, False);
                  Send (latest_message);
               else

                  -- did not find globe receive message
                  if Messages_Waiting then
                     Receive (message_get);
                     -- compare time with last time less go and send or
                     if To_Duration (time_now - message_get.comm_time) < To_Duration (time_now - latest_message.comm_time) and then message_get.globe_num > 0 then
                        latest_message := message_get;
                        if Current_Charge < latest_message.my_energy then
                           move_to_destination (latest_message, Position, Velocity, Acceleration, False);
                        elsif Current_Charge > 0.3 then
                              Set_Destination(Zero_Vector_3D);
                              Set_Throttle (0.5);
                        end if;

                        latest_message.my_energy := Current_Charge;
                        Send (latest_message);
                     else
                        --if Current_Charge < message_get.my_energy then
                           move_to_destination (latest_message, Position, Velocity, Acceleration, False);

                     --   end if;

                        latest_message.my_energy := Current_Charge;
                        Send (latest_message);
                     end if;

                  else
                     -- did not receive message
                     if get_speed (Velocity) < 0.002 then
                        Set_Destination (Zero_Vector_3D);
                        Set_Throttle(0.5);
                     else
                        move_to_destination (latest_message, Position, Velocity, Acceleration, True);
                     end if;
                     -- Send (latest_message);
                  end if;
               end if;
               -- null;
               Put_Line (Current_Charge'Image);
               -- Put_Line(get_distance (latest_message.globes_get (1).Position, Position)'Image);
            end;

         end loop Outer_task_loop;

      end select;

   exception
      when E : others => Show_Exception (E);

   end Vehicle_Task;

   procedure message_initialize (Msg : in out Inter_Vehicle_Messages) is
   begin
      Msg.comm_time := Ada.Real_Time.Clock;
      Msg.globe_num := 0;
   end message_initialize;

   procedure move_to_destination (latest_message : Inter_Vehicle_Messages; Position : Positions; Velocity : Velocities; Acceleration : Accelerations; Flag : Boolean) is
      pragma Unreferenced (Acceleration, Velocity);

   begin
      -- find the cloest globes
      declare
         ID : Integer := 1;
         distance : Real := (latest_message.globes_get (1).Position (x) - Position (x))**2 + (latest_message.globes_get (1).Position (y) - Position (y))**2 + (latest_message.globes_get (1).Position (z) - Position (z))**2;
      begin

         for i in 2 .. latest_message.globe_num loop
            if distance > (latest_message.globes_get (i).Position (x) - Position (x))**2 + (latest_message.globes_get (i).Position (y) - Position (y))**2 + (latest_message.globes_get (i).Position (z) - Position (z))**2 then
               distance := (latest_message.globes_get (i).Position (x) - Position (x))**2 + (latest_message.globes_get (i).Position (y) - Position (y))**2 + (latest_message.globes_get (i).Position (z) - Position (z))**2;
               ID := i;
            end if;
         end loop;

         -- set destination
         declare
            Radius_Vector : constant Positions := 0.025 * Norm (Position - latest_message.globes_get (ID).Position);
            tt : constant Real := 1.0; --+(distance * 1.0);
         begin
            -- Put_Line(latest_message.globe_num'Image);
            if Current_Charge < 0.4 or else Flag then
               -- move to des
               Set_Destination (latest_message.globes_get (ID).Position + Radius_Vector);
               Set_Throttle (tt);
              -- Put_Line (tt'Image);
            else
               Set_Throttle (Idle_Throttle);
            end if;
         end;
      end;
   end move_to_destination;

   function time_cost (Pos1, Pos2 : Positions; v1, v2 : Velocities; a : Accelerations) return Real is
      pragma Unreferenced (v1, Pos2, a, v2, Pos1);
   begin
      null;
      return 0.0;
   end time_cost;

   function get_speed (v1 : Velocities) return Real is
      dis : constant Real := v1 (x)**2 + v1 (y)**2 + v1 (z)**2;
   begin
      null;
      return dis;
   end get_speed;
end Vehicle_Task_Type;
