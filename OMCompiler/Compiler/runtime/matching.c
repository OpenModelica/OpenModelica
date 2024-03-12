/*
 * File: matching.c
 * Content: Contains maximum transversal algorithms
 * Author: Kamer Kaya, Johannes Langguth and Bora Ucar
 * Version: 0.3
 *
 * Please see the reports:
 *
 *   "I. S. Duff, K. Kaya and B. Ucar.
 *   'Design, Implementations and Analysis of Maximum Transversal Algorithms'
 *   CERFACS Tech. Report TR/PA/10/76, October, 2010."
 *
 *   "K. Kaya, J. Langguth, F. Manne and B. Ucar.
 *   'Experiments on Push-Relabel-based Maximum Cardinality Matching Algorithms for Bipartite Graphs'
 *   CERFACS Tech. Report TR/PA/11/33, May, 2011."
 *
 * for more details and cite them if you use the codes.
 *
 */

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <ctype.h>
#include <math.h>

#include "matchmaker.h"

#define max(a, b) (a > b ? a : b)

void match_dfs(int* col_ptrs, int* col_ids, int* match, int* row_match, int n, int m) {
  int* stack = (int*)malloc(sizeof(int) * n);
  int* colptrs = (int*)malloc(sizeof(int) * n);
  int* visited = (int*)malloc(sizeof(int) * m);

  int stack_col, ptr, temp, next_augment_no, i, j, row, col, eptr, stack_last,
  stack_end;
  memset(visited, 0, sizeof(int) * m);
  next_augment_no = 1;
  for(i = 0; i < n; i++) {
    if((match[i] == -1) && (col_ptrs[i] != col_ptrs[i+1])) {
      stack[0] = i; stack_last = 0;
      colptrs[i] = col_ptrs[i];
      stack_end = n;
      while(stack_last > -1) {
        stack_col = stack[stack_last];

        eptr = col_ptrs[stack_col + 1];
        for(ptr = colptrs[stack_col]; ptr < eptr; ptr++) {
          temp = visited[col_ids[ptr]];
          if(temp != next_augment_no && temp != -1) {
            break;
          }
        }
        colptrs[stack_col] = ptr + 1;

        if(ptr == eptr) {
          stack[--stack_end] = stack_col;
          --stack_last;
          continue;
        }

        row = col_ids[ptr]; visited[row] = next_augment_no;
        col = row_match[row];
        if(col == -1) {
          while(row != -1){
            col = stack[stack_last--];
            temp = match[col];
            match[col] = row; row_match[row] = col;
            row = temp;
          }

          next_augment_no++;
          break;
        } else {
          stack[++stack_last] = col;
          colptrs[col] = col_ptrs[col];
        }
      }

      if(match[i] == -1) {
        for(j = stack_end + 1; j < n; j++) {
          visited[match[stack[j]]] = -1;
        }
      }
    }
  }
  free(visited);
  free(colptrs);
  free(stack);
}

void match_bfs(int* col_ptrs, int* col_ids, int* match, int* row_match, int n, int m) {
  int* visited = (int*)malloc(sizeof(int) * m);
  int* queue = (int*)malloc(sizeof(int) * n);
  int* previous = (int*)malloc(sizeof(int) * m);

  int queue_ptr, queue_col, ptr, next_augment_no, i, j, queue_size,
  row, col, temp, eptr;

  memset(visited, 0, sizeof(int) * m);

  next_augment_no = 1;
  for(i = 0; i < n; i++) {
    if(match[i] == -1 && col_ptrs[i] != col_ptrs[i+1]) {
      queue[0] = i; queue_ptr = 0; queue_size = 1;

      while(queue_size > queue_ptr) {
        queue_col = queue[queue_ptr++];
        eptr = col_ptrs[queue_col + 1];
        for(ptr = col_ptrs[queue_col]; ptr < eptr; ptr++) {
          row = col_ids[ptr];
          temp = visited[row];

          if(temp != next_augment_no && temp != -1) {
            previous[row] = queue_col;
            visited[row] = next_augment_no;

            col = row_match[row];
            if(col == -1) {
              while(row != -1) {
                col = previous[row];
                temp = match[col];
                match[col] = row; row_match[row] = col;
                row = temp;
              }
              next_augment_no++;
              queue_size = 0;
              break;
            } else {
              queue[queue_size++] = col;
            }
          }
        }
      }

      if(match[i] == -1) {
        for(j = 1; j < queue_size; j++) {
          visited[match[queue[j]]] = -1;
        }
      }
    }
  }

  free(previous);
  free(queue);
  free(visited);
}

void match_mc21(int* col_ptrs, int* col_ids, int* match, int* row_match, int n, int m) {
  int* visited = (int*)malloc(sizeof(int) * m);
  int* stack = (int*)malloc(sizeof(int) * n);
  int* colptrs = (int*)malloc(sizeof(int) * n);
  int* lookahead = (int*)malloc(sizeof(int) * n);

  int stack_col, stack_last, ptr, next_augment_no, i,j, row, col,
  temp, eptr, stack_end;

  memset(visited, 0, sizeof(int) * m);
  memcpy(lookahead, col_ptrs, sizeof(int) * n);

  next_augment_no = 1;
  for(i = 0; i < n; i++) {
    if(match[i] == -1 && col_ptrs[i] != col_ptrs[i+1]) {
      stack[0] = i; stack_last = 0;
      colptrs[i] = col_ptrs[i];

      stack_end = n;

      while(stack_last > -1) {
        stack_col = stack[stack_last];

        eptr = col_ptrs[stack_col + 1];
        for(ptr = lookahead[stack_col];  ptr < eptr && row_match[col_ids[ptr]] != -1; ptr++){}
        lookahead[stack_col] = ptr + 1;

        if(ptr >= eptr) {
          for(ptr = colptrs[stack_col]; ptr < eptr; ptr++) {
            temp = visited[col_ids[ptr]];
            if(temp != next_augment_no && temp != -1) {
              break;
            }
          }
          colptrs[stack_col] = ptr + 1;

          if(ptr == eptr) {
            --stack_last;
            stack[--stack_end] = stack_col;
            continue;
          }

          row = col_ids[ptr]; visited[row] = next_augment_no;
          col = row_match[row]; stack[++stack_last] = col; colptrs[col] = col_ptrs[col];
        } else {
          row = col_ids[ptr]; visited[row] = next_augment_no;
          while(row != -1){
            col = stack[stack_last--];
            temp = match[col];
            match[col] = row; row_match[row] = col;
            row = temp;
          }
          next_augment_no++;
          break;
        }
      }

      if(match[i] == -1) {
        for(j = stack_end + 1; j < n; j++) {
          visited[match[stack[j]]] = -1;
        }
      }
    }
  }

  free(lookahead);
  free(colptrs);
  free(stack);
  free(visited);
}

void match_pf(int* col_ptrs, int* col_ids, int* match, int* row_match, int n, int m) {
  int* visited = (int*)malloc(sizeof(int) * m);
  int* stack = (int*)malloc(sizeof(int) * n);
  int* colptrs = (int*)malloc(sizeof(int) * n);
  int* lookahead = (int*)malloc(sizeof(int) * n);
  int* unmatched = (int*)malloc(sizeof(int) * n);

  int  i, j, row, col, stack_col, temp, ptr, eptr, stack_last,
  stop = 0, pcount = 1, stack_end_ptr, nunmatched = 0, nextunmatched = 0,
  current_col;

  memset(visited, 0, sizeof(int) * m);
  memcpy(lookahead, col_ptrs, sizeof(int) * n);

  for(i = 0; i < n; i++) {
    if(match[i] == -1 && col_ptrs[i] != col_ptrs[i+1]) {
      unmatched[nunmatched++] = i;
    }
  }

  while(!stop) {
    stop = 1;
    stack_end_ptr = n;
    for(i = 0; i < nunmatched; i++) {
      current_col = unmatched[i];
      stack[0] = current_col; stack_last = 0; colptrs[current_col] = col_ptrs[current_col];

      while(stack_last > -1) {
        stack_col = stack[stack_last];

        eptr = col_ptrs[stack_col + 1];
        for(ptr = lookahead[stack_col]; ptr < eptr && row_match[col_ids[ptr]] != -1; ptr++){}
        lookahead[stack_col] = ptr + 1;

        if(ptr >= eptr) {
          for(ptr = colptrs[stack_col]; ptr < eptr; ptr++) {
            temp = visited[col_ids[ptr]];
            if(temp != pcount && temp != -1) {
              break;
            }
          }
          colptrs[stack_col] = ptr + 1;

          if(ptr == eptr) {
            if(stop) {stack[--stack_end_ptr] = stack_col;}
            --stack_last;
            continue;
          }

          row = col_ids[ptr]; visited[row] = pcount;
          col = row_match[row]; stack[++stack_last] = col; colptrs[col] = col_ptrs[col];
        } else {
          row = col_ids[ptr]; visited[row] = pcount;
          while(row != -1){
            col = stack[stack_last--];
            temp = match[col];
            match[col] = row; row_match[row] = col;
            row = temp;
          }
          stop = 0;
          break;
        }
      }

      if(match[current_col] == -1) {
        if(stop) {
          for(j = stack_end_ptr + 1; j < n; j++) {
            visited[match[stack[j]]] = -1;
          }
          stack_end_ptr = n;
        } else {
          unmatched[nextunmatched++] = current_col;
        }
      }
    }
    pcount++; nunmatched = nextunmatched; nextunmatched = 0;
  }

  free(unmatched);
  free(lookahead);
  free(colptrs);
  free(stack);
  free(visited);
}


void match_pf_fair(int* col_ptrs, int* col_ids, int* match, int* row_match, int n, int m) {
  int* visited = (int*)malloc(sizeof(int) * m);
  int* stack = (int*)malloc(sizeof(int) * n);
  int* colptrs = (int*)malloc(sizeof(int) * n);
  int* lookahead = (int*)malloc(sizeof(int) * n);
  int* unmatched = (int*)malloc(sizeof(int) * n);

  int  i, j, row, col, stack_col, temp, ptr, eptr, stack_last,
  stop = 0, pcount = 1, stack_end_ptr, nunmatched = 0, nextunmatched = 0,
  current_col, inc = 1;
  size_t curStackSize = n;

  memset(visited, 0, sizeof(int) * m);
  memcpy(lookahead, col_ptrs, sizeof(int) * n);

  for(i = 0; i < n; i++) {
    if(match[i] == -1 && col_ptrs[i] != col_ptrs[i+1]) {
      unmatched[nunmatched++] = i;
    }
  }

  while(!stop) {
    stop = 1; stack_end_ptr = n;
    if(inc) {
      for(i = 0; i < nunmatched; i++) {
        current_col = unmatched[i];
        stack[0] = current_col; stack_last = 0; colptrs[current_col] = col_ptrs[current_col];

        while(stack_last > -1) {
          stack_col = stack[stack_last];

          eptr = col_ptrs[stack_col + 1];
          for(ptr = lookahead[stack_col]; ptr < eptr && row_match[col_ids[ptr]] != -1; ptr++){}
          lookahead[stack_col] = ptr + 1;

          if(ptr >= eptr) {
            for(ptr = colptrs[stack_col]; ptr < eptr; ptr++) {
              temp = visited[col_ids[ptr]];
              if(temp != pcount && temp != -1) {
                break;
              }
            }
            colptrs[stack_col] = ptr + 1;

            if(ptr == eptr) {
              if(stop) {stack[--stack_end_ptr] = stack_col;}
              --stack_last;
              continue;
            }

            row = col_ids[ptr];
            visited[row] = pcount;
            col = row_match[row];
            if (++stack_last >= curStackSize) {
              stack = realloc(stack, sizeof(int)*(curStackSize*=2));
            }
            stack[stack_last] = col;
            if (col >= n) {
              fprintf(stderr, "Reading outside of array row_match[%d]=%d, n=%d, m=%d\n", row, col, n, m);
            }
            colptrs[col] = col_ptrs[col];
          } else {
            row = col_ids[ptr]; visited[row] = pcount;
            while(row != -1){
              col = stack[stack_last--];
              temp = match[col];
              match[col] = row; row_match[row] = col;
              row = temp;
            }
            stop = 0;
            break;
          }
        }

        if(match[current_col] == -1) {
          if(stop) {
            for(j = stack_end_ptr + 1; j < n; j++) {
              visited[match[stack[j]]] = -1;
            }
            stack_end_ptr = n;
          } else {
            unmatched[nextunmatched++] = current_col;
          }
        }
      }
    } else {
      for(i = 0; i < nunmatched; i++) {
        current_col = unmatched[i];
        stack[0] = current_col; stack_last = 0; colptrs[current_col] = col_ptrs[current_col + 1] - 1;

        while(stack_last > -1) {
          stack_col = stack[stack_last];

          eptr = col_ptrs[stack_col + 1];
          for(ptr = lookahead[stack_col]; ptr < eptr && row_match[col_ids[ptr]] != -1; ptr++){}
          lookahead[stack_col] = ptr + 1;

          if(ptr >= eptr) {
            eptr = col_ptrs[stack_col] - 1;
            for(ptr = colptrs[stack_col]; ptr > eptr; ptr--) {
              temp = visited[col_ids[ptr]];
              if(temp != pcount && temp != -1) {
                break;
              }
            }
            colptrs[stack_col] = ptr - 1;

            if(ptr == eptr) {
              if(stop) {stack[--stack_end_ptr] = stack_col;}
              --stack_last;
              continue;
            }

            row = col_ids[ptr];
            visited[row] = pcount;
            col = row_match[row];
            if (++stack_last >= curStackSize) {
              stack = realloc(stack, sizeof(int)*(curStackSize*=2));
            }
            stack[stack_last] = col;
            colptrs[col] = col_ptrs[col + 1] - 1;

          } else {
            row = col_ids[ptr]; visited[row] = pcount;
            while(row != -1){
              col = stack[stack_last--];
              temp = match[col];
              match[col] = row; row_match[row] = col;
              row = temp;
            }
            stop = 0;
            break;
          }
        }

        if(match[current_col] == -1) {
          if(stop) {
            for(j = stack_end_ptr + 1; j < n; j++) {
              visited[match[stack[j]]] = -1;
            }
            stack_end_ptr = n;
          } else {
            unmatched[nextunmatched++] = current_col;
          }
        }
      }
    }
    pcount++; nunmatched = nextunmatched; nextunmatched = 0; inc = !inc;
  }

  free(unmatched);
  free(lookahead);
  free(colptrs);
  free(stack);
  free(visited);
}

void match_hk(int* col_ptrs, int* col_ids, int* row_ptrs, int* row_ids, int* match, int* row_match, int n, int m) {
  int* queue = (int*)malloc(sizeof(int) * n);
  int* stack = (int*)malloc(sizeof(int) * m);
  int* rowptrs = (int*)malloc(sizeof(int) * m);
  int* cvisited = (int*)malloc(sizeof(int) * n);
  int* rvisited = (int*)malloc(sizeof(int) * m);
  int* qpos = (int*)malloc(sizeof(int) * n);
  int* clevels = (int*)malloc(sizeof(int) * n);

  int i, queue_size, queue_ptr, queue_col, row, col, temp, stack_row, ptr, eptr,
  pcount = 1, ppcount, level_0, last_queue_size, L, desired, stack_last;

  memset(rvisited, 0, sizeof(int) * m);
  memset(cvisited, 0, sizeof(int) * n);

  level_0 = 0;
  for(i = n-1; i >= 0; i--) {
    if(match[i] == -1 && col_ptrs[i] != col_ptrs[i+1]) {
      qpos[i] = level_0;
      queue[level_0++] = i;
    }
  }

  while(1) {
    stack_last = -1;
    queue_size = level_0; queue_ptr = 0; L = 0;
    while(stack_last == -1 && queue_ptr < queue_size) {
      last_queue_size = queue_size; L += 2;
      while(queue_ptr < last_queue_size) {
        queue_col = queue[queue_ptr++];
        eptr = col_ptrs[queue_col + 1];
        for(ptr = col_ptrs[queue_col]; ptr < eptr; ptr++) {
          row = col_ids[ptr];
          if(rvisited[row] != pcount) {
            rvisited[row] = pcount;
            col = row_match[row];
            if(col == -1) {
              stack[++stack_last] = row;
              rowptrs[row] = row_ptrs[row];
            } else  {
              queue[queue_size++] = col;
              cvisited[col] = pcount;
              clevels[col] = L;
            }
          }
        }
      }
    }
    ppcount = pcount++;

    if(stack_last == -1) break;

    while(stack_last > -1) {
      stack_row = stack[stack_last];

      col = row_match[stack_row];
      if(col == -1) desired = L - 2; else desired = clevels[col] - 2;

      eptr = row_ptrs[stack_row + 1];
      for(ptr = rowptrs[stack_row]; ptr < eptr; ptr++) {
        col = row_ids[ptr];
        if(match[col] == -1 || (clevels[col] == desired && cvisited[col] == ppcount)) {
          cvisited[col] = pcount;
          break;
        }
      }
      rowptrs[stack_row] = ptr + 1;

      if(ptr < eptr) {
        row = match[col];
        if(row == -1) {
          qpos[queue[--level_0]] = qpos[col];
          queue[qpos[col]] = queue[level_0];

          while(col != -1){
            row = stack[stack_last--];
            temp = row_match[row];
            row_match[row] = col; match[col] = row;
            col = temp;
          }
        } else {
          stack[++stack_last] = row;
          rowptrs[row] = row_ptrs[row];
        }
      } else {
        --stack_last;
        continue;
      }
    }
    pcount++;
  }

  free(queue);
  free(stack);
  free(rowptrs);
  free(cvisited);
  free(rvisited);
  free(qpos);
  free(clevels);
}

void match_hk_dw(int* col_ptrs, int* col_ids, int* row_ptrs, int* row_ids,
    int* match, int* row_match, int n, int m) {

  int* queue = (int*)malloc(sizeof(int) * n);
  int* stack = (int*)malloc(sizeof(int) * m);
  int* rowptrs = (int*)malloc(sizeof(int) * m);
  int* lookahead = (int*)malloc(sizeof(int) * m);
  int* cvisited = (int*)malloc(sizeof(int) * n);
  int* rvisited = (int*)malloc(sizeof(int) * m);
  int* qpos = (int*)malloc(sizeof(int) * n);
  int* clevels = (int*)malloc(sizeof(int) * n);
  int* unmatched = (int*)malloc(sizeof(int) * m);


  int i, queue_size, queue_ptr, queue_col, row, col, temp, stack_row, ptr, eptr,
  pcount = 1, ppcount, level_0, last_queue_size, stack_last, nunmatched = 0,
  nextunmatched, current_row, desired, L;

  memset(rvisited, 0, sizeof(int) * m);
  memset(cvisited, 0, sizeof(int) * n);
  memcpy(lookahead, row_ptrs, sizeof(int) * m);

  for(i = 0; i < m; i++) {
    if(row_match[i] == -1 && row_ptrs[i] != row_ptrs[i+1]) {
      unmatched[nunmatched++] = i;
    }
  }

  level_0 = 0;
  for(i = n-1; i >= 0; i--) {
    if(match[i] == -1 && col_ptrs[i] != col_ptrs[i+1]) {
      qpos[i] = level_0;
      queue[level_0++] = i;
    }
  }

  while(1) {
    stack_last = -1;

    queue_size = level_0; queue_ptr = 0; L = 0;
    while(stack_last == -1 && queue_ptr < queue_size) {
      last_queue_size = queue_size; L += 2;
      while(queue_ptr < last_queue_size) {
        queue_col = queue[queue_ptr++];

        eptr = col_ptrs[queue_col + 1];
        for(ptr = col_ptrs[queue_col]; ptr < eptr; ptr++) {
          row = col_ids[ptr];
          if(rvisited[row] != pcount) {
            rvisited[row] = pcount;
            col = row_match[row];
            if(col == -1) {
              stack[++stack_last] = row;
              rowptrs[row] = row_ptrs[row];
            } else  {
              queue[queue_size++] = col;
              cvisited[col] = pcount;
              clevels[col] = L;
            }
          }
        }
      }
    }
    ppcount = pcount++;
    if(stack_last == -1) break;

    while(stack_last > -1) {
      stack_row = stack[stack_last];
      col = row_match[stack_row];
      if(col == -1) desired = L - 2; else desired = clevels[col] - 2;

      eptr = row_ptrs[stack_row + 1];
      for(ptr = rowptrs[stack_row]; ptr < eptr; ptr++) {
        col = row_ids[ptr];
        if(match[col] == -1 || (clevels[col] == desired && cvisited[col] == ppcount)) {
          cvisited[col] = pcount;
          break;
        }
      }
      rowptrs[stack_row] = ptr + 1;

      if(ptr < eptr) {
        row = match[col];
        if(row == -1) {
          qpos[queue[--level_0]] = qpos[col];
          queue[qpos[col]] = queue[level_0];

          while(col != -1){
            row = stack[stack_last--];
            temp = row_match[row];
            row_match[row] = col; match[col] = row;
            col = temp;
          }
        } else {
          stack[++stack_last] = row;
          rowptrs[row] = row_ptrs[row];
        }
      } else {
        --stack_last;
        continue;
      }
    }
    pcount++;

    nextunmatched = 0;
    for(i = 0; i < nunmatched; i++) {
      current_row = unmatched[i];
      if(row_match[current_row] == -1) {
        stack[0] = current_row; stack_last = 0;
        rowptrs[current_row] = row_ptrs[current_row];
        while(stack_last > -1) {
          stack_row = stack[stack_last];

          eptr = row_ptrs[stack_row + 1];
          for(ptr = lookahead[stack_row]; ptr < eptr && match[row_ids[ptr]] != -1; ptr++){}
          lookahead[stack_row] = ptr + 1;

          if(ptr >= eptr) {
            eptr = row_ptrs[stack_row + 1];
            for(ptr = rowptrs[stack_row]; ptr < eptr && cvisited[row_ids[ptr]] == pcount; ptr++) {}
            rowptrs[stack_row] = ptr + 1;

            if(ptr == eptr) {
              --stack_last;
              continue;
            }

            col = row_ids[ptr];  row = match[col];

            cvisited[col] = pcount;
            stack[++stack_last] = row;
            rowptrs[row] = row_ptrs[row];
          } else {
            col = row_ids[ptr]; cvisited[col] = pcount;

            qpos[queue[--level_0]] = qpos[col];
            queue[qpos[col]] = queue[level_0];

            while(col != -1){
              row = stack[stack_last--];
              temp = row_match[row];
              row_match[row] = col; match[col] = row;
              col = temp;
            }
            break;
          }
        }

        if(row_match[current_row] == -1) {
          unmatched[nextunmatched++] = current_row;
        }
      }
    }
    pcount++; nunmatched = nextunmatched;
  }

  free(queue);
  free(stack);
  free(rowptrs);
  free(cvisited);
  free(rvisited);
  free(lookahead);
  free(qpos);
  free(clevels);
  free(unmatched);
}

void match_abmp(int* col_ptrs, int* col_ids, int* row_ptrs, int* row_ids, int* match, int* row_match, int n, int m) {
  int v = max(m,n);

  int* queue = (int*)malloc(sizeof(int) * v);
  int* clevels = (int*)malloc(sizeof(int) * n);
  int* rvisited = (int*)malloc(sizeof(int) * m);
  int* colptrs = (int*)malloc(sizeof(int) * v);
  int* unmatched =  (int*)malloc(sizeof(int) * n);
  int* qpos = (int*)malloc(sizeof(int) * m);
  int* cvisited = (int*)malloc(sizeof(int) * n);
  int* stack = (int*)malloc(sizeof(int) * n);
  int* rlevels = (int*)malloc(sizeof(int) * m);

  int i,queue_size, queue_ptr, queue_row, row = -1, col = -1,
      temp, stack_col, ptr, eptr, next_col_i, start_col_i,
      pcount = 1, desired_level, L, desired, stack_last, current_col,
      lim = 0.1*sqrt(m + n), nunmatched = 0, level_ptr,
      update_counter = n, counter_limit = n, tunmatched = 0,level_0, ppcount = 0;

  level_0 = 0;
  for(i = 0; i < m; i++) {
    if(row_match[i] == -1 && row_ptrs[i] != row_ptrs[i+1]) {
      qpos[i] = level_0;
      queue[level_0++] = i;
    }
  }

  for(i = 0; i < n; i++) {if(match[i] == -1) {tunmatched++;} clevels[i] = n + m;}

  memset(cvisited, 0, sizeof(int) * n);
  while(1) {
    if(update_counter >= counter_limit) {
      update_counter = 0; L = 1; nunmatched = 0;
      queue_size = level_0;  queue_ptr = 0;
      while(queue_ptr < queue_size) {
        level_ptr = queue_size;
        while(queue_ptr < level_ptr) {
          queue_row = queue[queue_ptr++];

          eptr = row_ptrs[queue_row + 1];
          for(ptr = row_ptrs[queue_row]; ptr < eptr; ptr++) {
            col = row_ids[ptr];

            if(cvisited[col] != pcount) {
              cvisited[col] = pcount;
              clevels[col] = L;

              row = match[col];
              if(row == -1) {
                unmatched[nunmatched++] = col;
              } else {
                queue[queue_size++] = row;
              }
            }
          }
        }
        L += 2; if(L > lim  || 50*L > tunmatched) {break;}
      }
    }

    if(nunmatched == 0) {
      break;
    }
    start_col_i = 0; next_col_i = 0; L = clevels[unmatched[0]];

    while(next_col_i < nunmatched) {
      current_col = unmatched[next_col_i]; stack[0] = current_col; stack_last = 0;
      colptrs[current_col] = col_ptrs[current_col];

      while(stack_last > -1) {
        stack_col = stack[stack_last];
        desired_level = clevels[stack_col] - 2;

        eptr = col_ptrs[stack_col + 1];
        for(ptr = colptrs[stack_col]; ptr < eptr; ptr++){
          row = col_ids[ptr];
          col = row_match[row];
          if(col == -1 || clevels[col] == desired_level) {break;}
        }
        colptrs[stack_col] = ptr + 1;

        if(ptr == eptr) {
          clevels[stack_col] += 2;
          update_counter++;
          --stack_last;
          continue;
        }

        if(col == -1) {
          qpos[queue[--level_0]] = qpos[row];
          queue[qpos[row]] = queue[level_0];

          while(row != -1) {
            col = stack[stack_last--];
            temp = match[col];
            match[col] = row; row_match[row] = col;
            row = temp;
          }
          break;
        } else {
          stack[++stack_last] = col;
          colptrs[col] = col_ptrs[col];
        }
      }

      if(match[current_col] != -1) {
        tunmatched--;
        if(50*L > tunmatched) {break;}
        unmatched[next_col_i] = unmatched[start_col_i++];
      }
      next_col_i++;

      if(next_col_i < nunmatched && L != clevels[unmatched[next_col_i]]) {
        L = clevels[unmatched[start_col_i]];
        next_col_i = start_col_i;
      }
      if(update_counter >= counter_limit) {break;}
    }
    if(next_col_i == nunmatched || 50*L > tunmatched) {break;}
  }
  pcount++;

  memset(rvisited, 0, sizeof(int) * m);
  memset(cvisited, 0, sizeof(int) * n);
  while(1) {
    stack_last = -1;
    queue_size = level_0; queue_ptr = 0; L = 0;
    while(stack_last == -1 && queue_ptr < queue_size) {
      level_ptr = queue_size; L += 2;
      while(queue_ptr < level_ptr) {
        queue_row = queue[queue_ptr++];

        eptr = row_ptrs[queue_row + 1];
        for(ptr = row_ptrs[queue_row]; ptr < eptr; ptr++) {
          col = row_ids[ptr];
          if(cvisited[col] != pcount) {
            cvisited[col] = pcount;
            row = match[col];
            if(row == -1) {
              stack[++stack_last] = col;
              colptrs[col] = col_ptrs[col];
            } else  {
              queue[queue_size++] = row;
              rvisited[row] = pcount;
              rlevels[row] = L;
            }
          }
        }
      }
    }
    ppcount = pcount++;

    if(stack_last == -1) break;
    while(stack_last > -1) {
      stack_col = stack[stack_last];

      row = match[stack_col];
      if(row == -1) desired = L - 2; else desired = rlevels[row] - 2;

      eptr = col_ptrs[stack_col + 1];
      for(ptr = colptrs[stack_col]; ptr < eptr; ptr++) {
        row = col_ids[ptr];
        if(row_match[row] == -1 || (rlevels[row] == desired && rvisited[row] == ppcount)) {
          rvisited[row] = pcount;
          break;
        }
      }
      colptrs[stack_col] = ptr + 1;

      if(ptr < eptr) {
        col = row_match[row];
        if(col == -1) {

          qpos[queue[--level_0]] = qpos[row];
          queue[qpos[row]] = queue[level_0];

          while(row != -1){
            col = stack[stack_last--];
            temp = match[col];
            row_match[row] = col; match[col] = row;
            row = temp;
          }
        } else {
          stack[++stack_last] = col;
          colptrs[col] = col_ptrs[col];
        }
      } else {
        --stack_last;
        continue;
      }
    }
    pcount++;
  }

  free(queue);
  free(clevels);
  free(rvisited);
  free(colptrs);
  free(unmatched);
  free(qpos);
  free(cvisited);
  free(stack);
  free(rlevels);
}

void match_abmp_bfs(int* col_ptrs, int* col_ids, int* row_ptrs, int* row_ids, int* match, int* row_match, int n, int m) {
  int v = max(m,n);
  int* queue = (int*)malloc(sizeof(int) * v);
  int* visited = (int*)malloc(sizeof(int) * v);
  int* colptrs = (int*)malloc(sizeof(int) * v);
  int* previous = colptrs;
  int* unmatched = (int*)malloc(sizeof(int) * n);
  int* clevels = (int*)malloc(sizeof(int) * n);
  int* qpos = (int*)malloc(sizeof(int) * m);

  int i,j, queue_size, queue_ptr, queue_row, row = -1, col = -1,
      temp, stack_col, ptr, eptr, next_col_i, start_col_i,
      pcount = 1, desired_level, L, stack_last, current_col,
      lim = 0.1*sqrt(m + n), nunmatched = 0, level_0, level_ptr,
      update_counter = n, counter_limit = n, tunmatched = 0;

  int* stack;

  level_0 = 0;
  for(i = 0; i < m; i++) {
    if(row_match[i] == -1 && row_ptrs[i] != row_ptrs[i+1]) {
      qpos[i] = level_0;
      queue[level_0++] = i;
    }
  }

  for(i = 0; i < n; i++) {if(match[i] == -1) {tunmatched++;}clevels[i] = n+m;}

  memset(visited, 0, sizeof(int) * m);
  while(1) {
    if(update_counter >= counter_limit) {
      L = 1; nunmatched = 0; update_counter = 0;
      queue_size = level_0;  queue_ptr = 0;
      while(queue_ptr < queue_size) {
        level_ptr = queue_size;
        while(queue_ptr < level_ptr) {
          queue_row = queue[queue_ptr++];

          eptr = row_ptrs[queue_row + 1];
          for(ptr = row_ptrs[queue_row]; ptr < eptr; ptr++) {
            col = row_ids[ptr];

            if(visited[col] != pcount) {
              visited[col] = pcount;
              clevels[col] = L;

              row = match[col];
              if(row == -1) {
                unmatched[nunmatched++] = col;
              } else {
                queue[queue_size++] = row;
              }
            }
          }
        }
        L += 2; if(L > lim  || 50*L > tunmatched) {break;}
      }
    }

    if(nunmatched == 0) {
      break;
    }
    start_col_i = 0; next_col_i = 0; L = clevels[unmatched[0]];

    stack = &(queue[level_0]);
    while(next_col_i < nunmatched) {
      current_col = unmatched[next_col_i]; stack[0] = current_col; stack_last = 0;
      colptrs[current_col] = col_ptrs[current_col];

      while(stack_last > -1) {
        stack_col = stack[stack_last];
        desired_level = clevels[stack_col] - 2;

        eptr = col_ptrs[stack_col + 1];
        for(ptr = colptrs[stack_col]; ptr < eptr; ptr++){
          row = col_ids[ptr];
          col = row_match[row];
          if(col == -1 || clevels[col] == desired_level) {break;}
        }
        colptrs[stack_col] = ptr + 1;

        if(ptr == eptr) {
          clevels[stack_col] += 2;
          update_counter++;
          --stack_last;
          continue;
        }

        if(col == -1) {
          qpos[queue[--level_0]] = qpos[row];
          queue[qpos[row]] = queue[level_0];

          while(row != -1) {
            col = stack[stack_last--];
            temp = match[col];
            match[col] = row; row_match[row] = col;
            row = temp;
          }
          break;
        } else {
          stack[++stack_last] = col;
          colptrs[col] = col_ptrs[col];
        }
      }

      if(match[current_col] != -1) {
        tunmatched--;
        if(50*L > tunmatched) {break;}
        unmatched[next_col_i] = unmatched[start_col_i++];
      }
      next_col_i++;

      if(next_col_i < nunmatched && L != clevels[unmatched[next_col_i]]) {
        L = clevels[unmatched[start_col_i]];
        next_col_i = start_col_i;
      }
      if(update_counter >= counter_limit) {break;}
    }
    if(next_col_i == nunmatched || 50*L > tunmatched) {break;}
    pcount++;
  }

  memset(visited, 0, sizeof(int) * n);
  while(level_0 > 0) {
    queue_size = level_0; queue_ptr = level_0 - 1;

    while(queue_size > queue_ptr) {
      queue_row = queue[queue_ptr++];

      eptr = row_ptrs[queue_row + 1];
      for(ptr = row_ptrs[queue_row]; ptr < eptr; ptr++) {
        col = row_ids[ptr];

        if(visited[col] != level_0 && visited[col] != -1) {
          previous[col] = queue_row;
          visited[col] = level_0;

          row = match[col];
          if(row == -1) {
            while(col != -1) {
              row = previous[col];
              temp = row_match[row];
              match[col] = row; row_match[row] = col;
              col = temp;
            }
            queue_size = 0;
            break;
          } else {
            queue[queue_size++] = row;
          }
        }
      }
    }

    if(row_match[queue[level_0-1]] == -1) {
      for(j = level_0; j < queue_size; j++) {
        visited[row_match[queue[j]]] = -1;
      }
    }
    level_0--;
  }

  free(queue);
  free(visited);
  free(colptrs);
  free(unmatched);
  free(clevels);
  free(qpos);
}

void pr_global_relabel(int* l_label, int* r_label, int* row_ptrs, int* row_ids, int* match, int* row_match, int n, int m) {
  int* queue = (int*)malloc(sizeof(int) * m);
  int relabel_vertex;
  int i;
  int  queue_end=-1;
  int  queue_start=0;

  int max = n+m;

  for(i=0; i <n; i++) {
    l_label[i]=max;
  }

  for(i=0; i < m; i++) {
    if (row_match[i] == -1) {
      queue_end++;
      queue[queue_end] = i;
      r_label[i]=0;
    }
    else {
      r_label[i]=max;
    }
  }

  while (queue_end-queue_start>=0) {
    relabel_vertex=queue[queue_start];
    queue_start++;

    int ptr;
    int s_ptr = row_ptrs[relabel_vertex];
    int e_ptr = row_ptrs[relabel_vertex + 1];
    for(ptr = s_ptr; ptr < e_ptr; ptr++) {
      int left_vertex = row_ids[ptr];
      if(l_label[left_vertex] == max) {
        l_label[left_vertex]=r_label[relabel_vertex]+1;
        if (match[left_vertex]> -1) {
          if (r_label[match[left_vertex]] == max) {
            queue_end++;
            queue[queue_end]=match[left_vertex];
            r_label[match[left_vertex]]=l_label[left_vertex]+1;
          }
        }
      }
    }
  }
  free(queue);
}

void match_pr_fifo_fair(int* col_ptrs, int* col_ids, int* row_ptrs, int* row_ids, int* match, int* row_match, int n, int m, double relabel_period) {
  int* l_label = (int*)malloc(sizeof(int) * n);
  int* r_label = (int*)malloc(sizeof(int) * m);

  int* queue = (int*)malloc(sizeof(int) * n);
  int  queue_end = -1;
  int  queue_start = 0;

  int max = m + n;
  int limit = (int)(max*relabel_period);
  if (relabel_period == -1) limit = m;
  if (relabel_period == -2) limit = n;

  int i = 0;
  for(; i < n; i++) {
    if (match[i] == -1) {
      queue_end++;
      queue[queue_end]=i;
    }
  }
  pr_global_relabel(l_label, r_label, row_ptrs, row_ids, match, row_match, n, m);

  int min_vertex,max_vertex,min_label,next_vertex;
  int relabels=0;
  int queuesize = queue_end+1;

  while (queuesize>0) {
    max_vertex=queue[queue_start];
    queue_start = (queue_start+1)%n;
    queuesize--;

    if (relabels==limit) {
      pr_global_relabel(l_label, r_label, row_ptrs, row_ids, match, row_match, n, m);
      relabels=0;
    }

    min_label=max;
    relabels++;

    if (l_label[max_vertex]<max) {
      int ptr;
      int s_ptr = col_ptrs[max_vertex];
      int e_ptr = col_ptrs[max_vertex + 1];
      if (l_label[max_vertex]%4==1) {
        for(ptr = s_ptr; ptr < e_ptr; ptr++) {
          if(r_label[col_ids[ptr]] < min_label) {
            min_label=r_label[col_ids[ptr]];
            min_vertex=col_ids[ptr];
            if (r_label[min_vertex]==l_label[max_vertex]-1){
              relabels--;
              break;
            }
          }
        }
      } else {
        for(ptr = e_ptr-1; ptr >= s_ptr; ptr--) {
          if(r_label[col_ids[ptr]] < min_label) {
            min_label=r_label[col_ids[ptr]];
            min_vertex=col_ids[ptr];
            if (r_label[min_vertex]==l_label[max_vertex]-1)
            {
              relabels--;
              break;
            }
          }
        }
      }
    }

    if (min_label<max) {
      if (row_match[min_vertex]==-1){
        row_match[min_vertex]=max_vertex;
        match[max_vertex]=min_vertex;
      } else {
        next_vertex=row_match[min_vertex];
        queue_end = (queue_end+1)%n;
        queuesize++;
        queue[queue_end]=next_vertex;

        row_match[min_vertex]=max_vertex;
        match[max_vertex]=min_vertex;
        match[next_vertex]=-1;
        l_label[max_vertex]=min_label+1;
      }
      r_label[min_vertex]=min_label+2;
    }
  }

  free(queue);
  free(l_label);
  free(r_label);
}

void matching(int* col_ptrs, int* col_ids, int* match, int* row_match, int n, int m, int matching_id, int cheap_id, double relabel_period, int clear_match) {
  int* row_ptrs = NULL;
  int* row_ids = NULL;
  int i;

  if (clear_match==1)
  {
    for (i = 0; i < n; i++) {
      match[i] = -1;
    }
    for (i = 0; i < m; i++) {
      row_match[i] = -1;
    }
  }

  if(matching_id >= do_hk || cheap_id > do_old_cheap) {

    row_ptrs = (int*) malloc((m+1) * sizeof(int));
    memset(row_ptrs, 0, (m+1) * sizeof(int));

    int nz = col_ptrs[n];

    for(i = 0; i < nz; i++) {row_ptrs[col_ids[i]+1]++;}
    for(i = 0; i < m; i++) {row_ptrs[i+1] += row_ptrs[i];}

    int* t_row_ptrs = (int*) malloc(m * sizeof(int));
    memcpy(t_row_ptrs, row_ptrs, m * sizeof(int));

    row_ids = (int*) malloc(nz * sizeof(int));

    for(i = 0; i < n; i++) {
      int sp = col_ptrs[i];
      int ep = col_ptrs[i+1];

      for(;sp < ep; sp++) {
        int row = col_ids[sp];
        row_ids[t_row_ptrs[row]++] = i;
      }
    }
    free(t_row_ptrs);
  }

  cheap_matching(col_ptrs, col_ids, row_ptrs, row_ids, match, row_match, n, m, cheap_id);

  if(matching_id == do_dfs) {
    match_dfs(col_ptrs, col_ids, match, row_match, n, m);
  } else if(matching_id == do_bfs) {
    match_bfs(col_ptrs, col_ids, match, row_match, n, m);
  } else if(matching_id == do_mc21) {
    match_mc21(col_ptrs, col_ids, match, row_match, n, m);
  } else if(matching_id == do_pf) {
    match_pf(col_ptrs, col_ids, match, row_match, n, m);
  } else if(matching_id == do_pf_fair) {
    match_pf_fair(col_ptrs, col_ids, match, row_match, n, m);
  } else if(matching_id == do_hk) {
    match_hk(col_ptrs, col_ids, row_ptrs, row_ids, match, row_match, n, m);
  } else if(matching_id == do_hk_dw) {
    match_hk_dw(col_ptrs, col_ids, row_ptrs, row_ids, match, row_match, n, m);
  } else if(matching_id == do_abmp) {
    match_abmp(col_ptrs, col_ids, row_ptrs, row_ids, match, row_match, n, m);
  } else if(matching_id == do_abmp_bfs) {
    match_abmp_bfs(col_ptrs, col_ids, row_ptrs, row_ids, match, row_match, n, m);
  } else if(matching_id == do_pr_fifo_fair) {
    match_pr_fifo_fair(col_ptrs, col_ids, row_ptrs, row_ids, match, row_match, n, m, relabel_period);
  }
  if(matching_id >= do_hk || cheap_id > do_old_cheap) {
    free(row_ids);
    free(row_ptrs);
  }
}
