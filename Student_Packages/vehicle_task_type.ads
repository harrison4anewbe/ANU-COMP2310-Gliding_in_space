with Ada.Task_Identification; use Ada.Task_Identification;
with Vehicle_Message_Type;  use Vehicle_Message_Type;
with Swarm_Structures_Base; use Swarm_Structures_Base;
with Real_Type;                  use Real_Type;

package Vehicle_Task_Type is

   task type Vehicle_Task is
      entry Identify (Set_Vehicle_No : Positive; Local_Task_Id : out Task_Id);
   end Vehicle_Task;

   procedure message_initialize (Msg : in out Inter_Vehicle_Messages);
   procedure move_to_destination (latest_message : Inter_Vehicle_Messages; Position : Positions; Velocity : Velocities; Acceleration : Accelerations; Flag : Boolean);
   function time_cost (Pos1, Pos2 : Positions; v1, v2 : Velocities; a : Accelerations) return Real;
   function get_speed (v1 : Velocities) return Real;
end Vehicle_Task_Type;
